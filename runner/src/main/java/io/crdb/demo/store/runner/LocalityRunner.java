package io.crdb.demo.store.runner;

import io.crdb.demo.store.common.Authorization;
import org.apache.commons.lang3.RandomStringUtils;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.util.StopWatch;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.*;
import java.util.Collections;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;


@Component
public class LocalityRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(LocalityRunner.class);

    private static final String SELECT_AVAILABLE_BALANCE_SQL = "select acct.ACCT_BAL_AMT, SUM(auth.AUTH_AMT) from acct left outer join auth on acct.acct_nbr = auth.acct_nbr and acct.state = auth.state and auth.AUTH_STAT_CD = 0 where acct.acct_nbr = ? and acct.state = ? and acct.ACCT_STAT_CD = 1 group by ACCT_BAL_AMT";
    private static final String INSERT_AUTHORIZATION_SQL = "insert into AUTH(ACCT_NBR, REQUEST_ID, AUTH_ID, AUTH_AMT, AUTH_STAT_CD, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, STATE) values (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    private static final String UPDATE_AUTHORIZATION_SQL = "update AUTH set AUTH_STAT_CD = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ? where ACCT_NBR = ? and STATE = ? and REQUEST_ID = ? and AUTH_STAT_CD = 0";
    private static final String UPDATE_ACCOUNT_SQL = "update ACCT set ACCT_BAL_AMT = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ? where ACCT_NBR = ? and STATE = ? and ACCT_STAT_CD = 1";

    private static final String RETRY_SQL_STATE = "40001";
    private static final String SAVEPOINT = "cockroach_restart";
    private static final double PURCHASE_AMOUNT = 5.00;

    private final DataSource dataSource;
    private final ConfigurableApplicationContext context;

    private final AtomicInteger globalInsertRetryCounter = new AtomicInteger(0);
    private final AtomicInteger globalUpdateRetryCounter = new AtomicInteger(0);

    private static final Set<String> uniqueAccounts = Collections.newSetFromMap(new ConcurrentHashMap<>());

    @Value("${crdb.region}")
    private String region;

    @Value("${crdb.state}")
    private String state;

    @Value("${crdb.run.duration}")
    private int duration;

    @Value("${crdb.accts}")
    private int accounts;

    @Value("${crdb.log.batch}")
    private int logBatch;

    private int threadCount;

    @Autowired
    public LocalityRunner(DataSource dataSource, Environment environment, ConfigurableApplicationContext context) {
        this.dataSource = dataSource;
        this.context = context;

        threadCount = Runtime.getRuntime().availableProcessors();

        String threads = environment.getProperty("crdb.run.threads");

        if (StringUtils.isNotBlank(threads)) {
            threadCount = Integer.parseInt(threads);
        }

    }

    @Override
    public void run(ApplicationArguments args) {


        if (args.containsOption("run")) {
            final String testId = RandomStringUtils.randomAlphanumeric(8);
            runTest(testId, state, duration);
        }

        SpringApplication.exit(context, () -> 0);
    }

    private void runTest(String testId, String state, int duration) {

        String startBuilder = "\n" +
                "\tTest Details\n" +
                "\t\tTest ID: " + testId + '\n' +
                "\t\tDuration: " + duration + '\n' +
                "\t\tState: " + state + '\n' +
                "\t\tRegion: " + region + '\n' +
                "\t\t# Threads: " + threadCount + '\n' +
                "\t\tAccount Number Upper Bound: " + accounts + '\n';

        logger.info(startBuilder);

        final ExecutorService poolService = Executors.newFixedThreadPool(threadCount);
        final CountDownLatch countDownLatch = new CountDownLatch(threadCount);
        final AtomicLong transactions = new AtomicLong(0);
        final AtomicLong unavailableBalance = new AtomicLong(0);

        final StopWatch sw = new StopWatch();
        sw.start();

        int counter = 0;

        while (counter < threadCount) {

            poolService.execute(() -> {

                for (long stop = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(duration); stop > System.currentTimeMillis(); ) {
                    makePurchase(testId, state, transactions, unavailableBalance);
                }

                countDownLatch.countDown();

            });

            counter++;

        }


        try {
            countDownLatch.await();
        } catch (InterruptedException e) {
            logger.error(e.getMessage(), e);
        } finally {
            logger.info("shutting down ExecutorService");

            poolService.shutdown();
        }

        sw.stop();

        int touchedAccounts = getTouchedAccounts(testId, state);

        String endBuilder = "\n" +
                "\tTest Summary\n" +
                "\t\tTest ID: " + testId + '\n' +
                "\t\tDuration: " + duration + '\n' +
                "\t\tState: " + state + '\n' +
                "\t\tRegion: " + region + '\n' +
                "\t\t# Threads: " + threadCount + '\n' +
                "\t\t# Transactions Completed: " + transactions.get() + '\n' +
                "\t\t# Unique Accounts Used: " + uniqueAccounts.size() + '\n' +
                "\t\t# Accounts Updated: " + touchedAccounts + '\n' +
                "\t\t# Update Retries: " + globalUpdateRetryCounter.get() + '\n' +
                "\t\t# Insert Retries: " + globalInsertRetryCounter.get() + '\n' +
                "\t\t# Balances Not Found: " + unavailableBalance.get() + '\n' +
                "\t\tTotal Time in MS: " + sw.getTotalTimeMillis() + '\n';

        logger.info(endBuilder);

        if (touchedAccounts != uniqueAccounts.size()) {
            logger.error("number of accounts updated {} does not equal number of unique accounts used {}", touchedAccounts, uniqueAccounts.size());
        }
    }

    private void makePurchase(String testId, String state, AtomicLong transactions, AtomicLong unavailableBalance) {
        String accountNumber = getAccountNumber(state);

        logger.debug("making purchase for for account number [{}]", accountNumber);

        Double availableBalance = getAvailableBalance(accountNumber, state);

        if (availableBalance != null) {

            // for now we are ignoring balance
            Authorization authorization = createAuthorization(accountNumber, state, testId);

            double newBalance = availableBalance - PURCHASE_AMOUNT;

            updateRecords(authorization, newBalance);

            if (transactions.getAndIncrement() % logBatch == 0) {
                logger.info("processed {} transactions", transactions.get());
            }
        } else {
            unavailableBalance.incrementAndGet();
            logger.warn("unable to find balance for account number {} and state {}", accountNumber, state);
        }
    }

    private String getAccountNumber(String state) {
        final int random = ThreadLocalRandom.current().nextInt(1, accounts);

        String accountNumber = state + "-" + String.format("%022d", random);

        final boolean added = uniqueAccounts.add(accountNumber);

        if (!added) {
            logger.warn("account number {} has already been used, getting another...", accountNumber);
           accountNumber = getAccountNumber(state);
        }

        return accountNumber;
    }

    private int getTouchedAccounts(String testId, String state) {
        int count = 0;

        try (Connection connection = dataSource.getConnection()) {
            try (PreparedStatement ps = connection.prepareStatement("select count(distinct ACCT_NBR) from acct where state = ? and LAST_UPD_USER_ID = ?")) {
                ps.setString(1, state);
                ps.setString(2, testId);

                try (ResultSet rs = ps.executeQuery()) {

                    if (rs != null) {
                        if (rs.next()) {
                            count = rs.getInt(1);

                        }
                    }
                }
            }
        } catch (SQLException e) {
            logger.error(e.getMessage(), e);
        }
        return count;
    }


    private Double getAvailableBalance(String accountNumber, String state) {

        try (Connection connection = dataSource.getConnection()) {

            try (PreparedStatement ps = connection.prepareStatement(SELECT_AVAILABLE_BALANCE_SQL)) {

                ps.setString(1, accountNumber);
                ps.setString(2, state);

                try (ResultSet rs = ps.executeQuery()) {

                    if (rs != null) {
                        if (rs.next()) {
                            double accountBalance = rs.getDouble(1);
                            double holds = rs.getDouble(2);

                            return accountBalance - holds;
                        }
                    }
                }

            } catch (SQLException e) {
                logger.error(e.getMessage(), e);
            }

        } catch (SQLException e) {
            logger.error(e.getMessage(), e);
        }

        return null;


    }

    private Authorization createAuthorization(String accountNumber, String state, String testId) {

        Authorization auth = null;

        try (Connection connection = dataSource.getConnection()) {

            connection.setAutoCommit(false);

            int localRetryCount = 1;

            while (true) {

                Savepoint sp = connection.setSavepoint(SAVEPOINT);

                try (PreparedStatement ps = connection.prepareStatement(INSERT_AUTHORIZATION_SQL)) {

                    final Timestamp now = new Timestamp(System.currentTimeMillis());

                    auth = new Authorization();
                    auth.setAccountNumber(accountNumber);
                    auth.setRequestId(UUID.randomUUID());
                    auth.setAuthorizationId(RandomStringUtils.randomAlphanumeric(64));
                    auth.setAuthorizationAmount(new BigDecimal(PURCHASE_AMOUNT));
                    auth.setAuthorizationStatus(0);
                    auth.setCreatedTimestamp(now);
                    auth.setLastUpdatedTimestamp(now);
                    auth.setLastUpdatedUserId(testId);
                    auth.setState(state);

                    ps.setString(1, auth.getAccountNumber());
                    ps.setObject(2, auth.getRequestId());
                    ps.setString(3, auth.getAuthorizationId());
                    ps.setBigDecimal(4, auth.getAuthorizationAmount());
                    ps.setInt(5, auth.getAuthorizationStatus());
                    ps.setTimestamp(6, auth.getCreatedTimestamp());
                    ps.setTimestamp(7, auth.getLastUpdatedTimestamp());
                    ps.setString(8, auth.getLastUpdatedUserId());
                    ps.setString(9, auth.getState());

                    final int updated = ps.executeUpdate();

                    if (updated != 1) {
                        logger.warn("unexpected update count on create authorization");
                    }

                    connection.releaseSavepoint(sp);

                    connection.commit();

                    break;

                } catch (SQLException e) {

                    String sqlState = e.getSQLState();

                    if (RETRY_SQL_STATE.equals(sqlState)) {
                        logger.warn("attempt {}: rolling back INSERT for account number {}", localRetryCount, accountNumber);
                        localRetryCount++;
                        globalInsertRetryCounter.incrementAndGet();

                        connection.rollback(sp);

                    } else {
                        throw e;
                    }
                }

            }

            connection.setAutoCommit(true);

        } catch (SQLException e) {
            logger.error(e.getMessage(), e);
        }

        return auth;
    }


    private void updateRecords(Authorization authorization, double newBalance) {

        try (Connection connection = dataSource.getConnection()) {

            connection.setAutoCommit(false);

            int localRetryCount = 1;

            while (true) {

                Savepoint sp = connection.setSavepoint(SAVEPOINT);

                try {

                    try (PreparedStatement ps = connection.prepareStatement(UPDATE_AUTHORIZATION_SQL)) {
                        Timestamp now = new Timestamp(System.currentTimeMillis());

                        ps.setInt(1, 1);
                        ps.setTimestamp(2, now);
                        ps.setString(3, authorization.getLastUpdatedUserId());
                        ps.setString(4, authorization.getAccountNumber());
                        ps.setString(5, authorization.getState());
                        ps.setObject(6, authorization.getRequestId());

                        final int updated = ps.executeUpdate();

                        if (updated != 1) {
                            logger.warn("unexpected update count on update authorization");
                        }
                    }

                    try (PreparedStatement ps = connection.prepareStatement(UPDATE_ACCOUNT_SQL)) {
                        Timestamp now = new Timestamp(System.currentTimeMillis());

                        ps.setBigDecimal(1, new BigDecimal(newBalance));
                        ps.setTimestamp(2, now);
                        ps.setString(3, authorization.getLastUpdatedUserId());
                        ps.setString(4, authorization.getAccountNumber());
                        ps.setString(5, authorization.getState());

                        final int updated = ps.executeUpdate();

                        if (updated != 1) {
                            logger.warn("unexpected update count on update account");
                        }
                    }

                    connection.releaseSavepoint(sp);

                    connection.commit();

                    break;

                } catch (SQLException e) {
                    String sqlState = e.getSQLState();

                    if (RETRY_SQL_STATE.equals(sqlState)) {
                        logger.warn("attempt {}: rolling back UPDATE for account number {}", localRetryCount, authorization.getAccountNumber());
                        localRetryCount++;
                        globalUpdateRetryCounter.incrementAndGet();

                        connection.rollback(sp);


                    } else {
                        throw e;
                    }
                }
            }

            connection.setAutoCommit(true);

        } catch (SQLException e) {
            logger.error(e.getMessage(), e);
        }

    }

}
