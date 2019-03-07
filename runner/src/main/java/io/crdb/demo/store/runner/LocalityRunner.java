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

    private final DataSource dataSource;
    private final Environment environment;
    private final ConfigurableApplicationContext context;

    private final AtomicInteger globalInsertRetryCounter = new AtomicInteger(0);
    private final AtomicInteger globalUpdateRetryCounter = new AtomicInteger(0);

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

    @Autowired
    public LocalityRunner(DataSource dataSource, Environment environment, ConfigurableApplicationContext context) {
        this.dataSource = dataSource;
        this.environment = environment;
        this.context = context;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (args.containsOption("run")) {
            runTests(state, duration);
        }

        SpringApplication.exit(context, () -> 0);
    }

    private void runTests(String state, int duration) {

        final String testId = RandomStringUtils.randomAlphanumeric(8);

        logger.info("unique test id [{}]", testId);

        logger.info("running tests for [{}] minutes with state as [{}]", duration, state);

        Set<String> uniqueAccounts = Collections.newSetFromMap(new ConcurrentHashMap<>());

        int threadCount = Runtime.getRuntime().availableProcessors();

        String threads = environment.getProperty("crdb.run.threads");

        if (StringUtils.isNotBlank(threads)) {
            threadCount = Integer.parseInt(threads);
        }

        logger.info("starting ExecutorService with {} threads", threadCount);

        final ExecutorService poolService = Executors.newFixedThreadPool(threadCount);

        double purchaseAmount = 5.00;

        final CountDownLatch countDownLatch = new CountDownLatch(threadCount);

        int counter = 0;

        AtomicLong transactions = new AtomicLong(0);
        AtomicLong unavailableBalance = new AtomicLong(0);

        logger.info("upper limit for random account number is {}", accounts);

        StopWatch sw = new StopWatch(String.format("test with state [%s] for [%d] minutes", state, duration));
        sw.start();

        while (counter < threadCount) {

            poolService.execute(() -> {

                for (long stop = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(duration); stop > System.currentTimeMillis(); ) {

                    final int random = ThreadLocalRandom.current().nextInt(1, accounts);

                    String accountNumber = state + "-" + String.format("%022d", random);

                    uniqueAccounts.add(accountNumber);

                    logger.debug("running test for account number [{}]", accountNumber);

                    Double availableBalance = getAvailableBalance(accountNumber, state);

                    if (availableBalance != null) {

                        // for now we are ignoring balance
                        Authorization authorization = createAuthorization(accountNumber, purchaseAmount, state, testId);

                        double newBalance = availableBalance - purchaseAmount;

                        updateRecords(authorization, newBalance);

                        if (transactions.getAndIncrement() % logBatch == 0) {
                            logger.info("processed {} transactions", transactions.get());
                        }
                    } else {
                        unavailableBalance.incrementAndGet();
                        logger.warn("unable to find balance for account number {} and state {}", accountNumber, state);
                    }
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

        logger.info("**** | processed {} total transactions in {} ms or {} minutes using {} threads", transactions.get(), sw.getTotalTimeMillis(), TimeUnit.MILLISECONDS.toMinutes(sw.getTotalTimeMillis()), threadCount);
        logger.info("**** | there were {} retries on insert and {} retries on update", globalInsertRetryCounter.get(), globalUpdateRetryCounter.get());
        logger.info("**** | unable to find {} account balances", unavailableBalance.get());

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

        if (count != uniqueAccounts.size()) {
            logger.error("number of updates to acct {} does not equal number of unique accounts visited {}", count, uniqueAccounts.size());
        }


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

    private Authorization createAuthorization(String accountNumber, double purchaseAmount, String state, String testId) {

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
                    auth.setAuthorizationAmount(new BigDecimal(purchaseAmount));
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
