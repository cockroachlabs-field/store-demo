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
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;


@Component
public class LocalityRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(LocalityRunner.class);

    private static final String SELECT_AVAILABLE_BALANCE_SQL = "select acct.ACCT_BAL_AMT, SUM(auth.AUTH_AMT) from acct left outer join auth on acct.acct_nbr = auth.acct_nbr and acct.state = auth.state and auth.AUTH_STAT_CD = 0 where acct.acct_nbr = ? and acct.state = ? and acct.ACCT_STAT_CD = 1 group by ACCT_BAL_AMT";
    private static final String INSERT_AUTHORIZATION_SQL = "insert into AUTH(ACCT_NBR, REQUEST_ID, AUTH_ID, AUTH_AMT, AUTH_STAT_CD, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, STATE) values (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    private static final String UPDATE_AUTHORIZATION_SQL = "update AUTH set AUTH_STAT_CD = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ? where ACCT_NBR = ? and STATE = ? and REQUEST_ID = ? and AUTH_STAT_CD = 0";
    private static final String UPDATE_ACCOUNT_SQL = "update ACCT set ACCT_BAL_AMT = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ?, STATE = ? where ACCT_NBR = ? and STATE = ? and ACCT_STAT_CD = 1";

    private static final String RETRY_SQL_STATE = "40001";
    private static final String SAVEPOINT = "cockroach_restart";
    private static final double PURCHASE_AMOUNT = 5.00;

    private final DataSource dataSource;
    private final ConfigurableApplicationContext context;

    private final AtomicInteger globalInsertRetryCounter = new AtomicInteger(0);
    private final AtomicInteger globalUpdateRetryCounter = new AtomicInteger(0);

    private final AtomicInteger globalUpdateCounter = new AtomicInteger(0);
    private final AtomicInteger globalSelectCounter = new AtomicInteger(0);
    private final AtomicInteger globalInsertCounter = new AtomicInteger(0);

    @Value("${crdb.region}")
    private String region;

    @Value("${crdb.state}")
    private String state;

    @Value("${crdb.run.duration}")
    private int duration;

    @Value("${crdb.accts.total}")
    private int totalAccounts;

    @Value("${crdb.accts.states}")
    private int numStates;

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

        final String testId = RandomStringUtils.randomAlphanumeric(8);

        if (args.containsOption("run")) {
            runTest(testId, state, duration);
        }

        if (args.containsOption("locality")) {
            runTest(testId, state, duration);
            runTest(testId, state, duration);
        }

        SpringApplication.exit(context, () -> 0);
    }

    private void runTest(String testId, String state, int duration) {

        int accountsPerState = totalAccounts / numStates;

        String startBuilder = "\n" +
                "\tTest Details\n" +
                "\t\tTest ID: " + testId + '\n' +
                "\t\tDuration: " + duration + '\n' +
                "\t\tState: " + state + '\n' +
                "\t\tRegion: " + region + '\n' +
                "\t\t# Threads: " + threadCount + '\n' +
                "\t\t# Total Accounts: " + totalAccounts + '\n' +
                "\t\t# Accounts Per State: " + accountsPerState + '\n';

        logger.info(startBuilder);

        final ExecutorService poolService = Executors.newFixedThreadPool(threadCount);
        final CountDownLatch countDownLatch = new CountDownLatch(threadCount);
        final AtomicLong transactions = new AtomicLong(0);
        final AtomicLong unavailableBalance = new AtomicLong(0);

        final StopWatch sw = new StopWatch();
        sw.start();

        int counter = 0;

        final List<Range> ranges = Range.buildRanges(accountsPerState, threadCount);

        while (counter < threadCount) {

            final Range range = ranges.get(counter);

            poolService.execute(() -> {

                long stop = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(duration);

                for (int i = range.getStart(); i < range.getEnd(); i++) {

                    if (stop <= System.currentTimeMillis()) {
                        break;
                    }

                    final String accountNumber = getAccountNumber(state, i);

                    makePurchase(testId, accountNumber, state, transactions, unavailableBalance);
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
                "\t\t# Total Accounts: " + totalAccounts + '\n' +
                "\t\t# Accounts Per State: " + accountsPerState + '\n' +
                "\t\t# Transactions Completed: " + transactions.get() + '\n' +
                "\t\t# Accounts Updated: " + touchedAccounts + '\n' +
                "\t\t# Update Retries: " + globalUpdateRetryCounter.get() + '\n' +
                "\t\t# Insert Retries: " + globalInsertRetryCounter.get() + '\n' +
                "\t\t# Selects: " + globalSelectCounter.get() + '\n' +
                "\t\t# Updates: " + globalUpdateCounter.get() + '\n' +
                "\t\t# Inserts: " + globalInsertCounter.get() + '\n' +
                "\t\t# Balances Not Found: " + unavailableBalance.get() + '\n' +
                "\t\tTotal Time in MS: " + sw.getTotalTimeMillis() + '\n';

        logger.info(endBuilder);

        if (touchedAccounts != transactions.get()) {
            logger.error("number of accounts updated {} does not equal number of transactions completed {}", touchedAccounts, transactions.get());
        }
    }

    private void makePurchase(String testId, String accountNumber, String state, AtomicLong transactions, AtomicLong unavailableBalance) {

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

    private String getAccountNumber(String state, int number) {
        return state + "-" + String.format("%022d", number);
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
            } finally {
                globalSelectCounter.incrementAndGet();
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
                } finally {
                    globalInsertCounter.incrementAndGet();
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
                    } finally {
                        globalUpdateCounter.incrementAndGet();
                    }

                    try (PreparedStatement ps = connection.prepareStatement(UPDATE_ACCOUNT_SQL)) {
                        Timestamp now = new Timestamp(System.currentTimeMillis());

                        ps.setBigDecimal(1, new BigDecimal(newBalance));
                        ps.setTimestamp(2, now);
                        ps.setString(3, authorization.getLastUpdatedUserId());
                        ps.setString(4, authorization.getState());
                        ps.setString(5, authorization.getAccountNumber());
                        ps.setString(6, authorization.getState());

                        final int updated = ps.executeUpdate();

                        if (updated != 1) {
                            logger.warn("unexpected update count on update account");
                        }
                    } finally {
                        globalUpdateCounter.incrementAndGet();
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
