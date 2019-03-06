package io.crdb.demo.store.runner;

import io.crdb.demo.store.common.Authorization;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
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
import java.util.UUID;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;


@Component
public class StartupRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(StartupRunner.class);

    private static final String SELECT_AVAILABLE_BALANCE_SQL = "select acct.ACCT_BAL_AMT, SUM(auth.AUTH_AMT) from acct left outer join auth on acct.acct_nbr = auth.acct_nbr and acct.state = auth.state and auth.AUTH_STAT_CD = 0 where acct.acct_nbr = ? and acct.state = ? and acct.ACCT_STAT_CD = 1 group by ACCT_BAL_AMT";

    private static final String INSERT_AUTHORIZATION_SQL = "insert into AUTH(ACCT_NBR, REQUEST_ID, AUTH_ID, AUTH_AMT, AUTH_STAT_CD, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, STATE) values (?, ?, ?, ?, ?, ?, ?, ?, ?)";

    private static final String UPDATE_AUTHORIZATION_SQL = "update AUTH set AUTH_STAT_CD = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ? where ACCT_NBR = ? and STATE = ? and REQUEST_ID = ? and AUTH_STAT_CD = 0";

    private static final String UPDATE_ACCOUNT_SQL = "update ACCT set ACCT_BAL_AMT = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ? where ACCT_NBR = ? and STATE = ? and ACCT_STAT_CD = 1";


    private static final String RETRY_SQL_STATE = "40001";
    private static final String SAVEPOINT = "cockroach_restart";

    private final DataSource dataSource;
    private final Environment environment;
    private final ConfigurableApplicationContext context;

    private final Timer availableBalanceTimer;
    private final Timer createAuthorizationTimer;
    private final Timer updateRecordsTimer;

    private final AtomicInteger insertRetryCounter = new AtomicInteger(0);
    private final AtomicInteger updateRetryCounter = new AtomicInteger(0);


    @Value("${crdb.region}")
    private String region;

    @Value("${crdb.state}")
    private String state;

    @Value("${crdb.run.duration}")
    private int duration;

    @Value("${crdb.accts}")
    private int accounts;

    @Autowired
    public StartupRunner(DataSource dataSource, Environment environment, MeterRegistry meterRegistry, ConfigurableApplicationContext context) {
        this.dataSource = dataSource;
        this.environment = environment;
        this.context = context;

        availableBalanceTimer = Timer.builder("runner.available_balance")
                .description("query available balance")
                .publishPercentileHistogram()
                .register(meterRegistry);

        createAuthorizationTimer = Timer.builder("runner.create_auth")
                .description("create authorization")
                .publishPercentileHistogram()
                .register(meterRegistry);

        updateRecordsTimer = Timer.builder("runner.update_records")
                .description("update records")
                .publishPercentileHistogram()
                .register(meterRegistry);
    }

    @Override
    public void run(ApplicationArguments args) {
        if (args.containsOption("run")) {
            runTests();
        }
    }

    private void runTests() {

        logger.info("running tests for [{}] minutes with state as [{}]", duration, state);

        runTests(state, duration);

    }

    private void runTests(String state, int duration) {

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

        logger.info("upper limit for random account number is {}", accounts);

        StopWatch sw = new StopWatch(String.format("test with state [%s] for [%d] minutes", state, duration));
        sw.start();

        while (counter < threadCount) {

            poolService.execute(() -> {

                for (long stop = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(duration); stop > System.currentTimeMillis(); ) {

                    final int random = ThreadLocalRandom.current().nextInt(1, accounts);

                    String accountNumber = state + "-" + String.format("%022d", random);

                    logger.debug("running test for account number [{}]", accountNumber);

                    Double availableBalance = getAvailableBalance(accountNumber, state);

                    // for now we are ignoring balance
                    Authorization authorization = createAuthorization(accountNumber, purchaseAmount, state);

                    double newBalance = availableBalance - purchaseAmount;

                    updateRecords(authorization, newBalance);

                    if (transactions.getAndIncrement() % 1000 == 0) {
                        logger.info("processed {} transactions", transactions.get());
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

        logger.info("*************** | `processed {} total transactions in {} ms or {} minutes", counter, sw.getTotalTimeMillis(), TimeUnit.MILLISECONDS.toMinutes(sw.getTotalTimeMillis()));
        logger.info("*************** |  there were {} retries on insert and {} retries on update", insertRetryCounter.get(), updateRetryCounter.get());

        SpringApplication.exit(context, () -> 0);
    }


    private double getAvailableBalance(String accountNumber, String state) {

        return availableBalanceTimer.record(() -> {

            double availableBalance = 0.0;

            try (Connection connection = dataSource.getConnection()) {

                try (PreparedStatement ps = connection.prepareStatement(SELECT_AVAILABLE_BALANCE_SQL)) {

                    ps.setString(1, accountNumber);
                    ps.setString(2, state);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (rs != null) {
                            if (rs.next()) {
                                double accountBalance = rs.getDouble(1);
                                double holds = rs.getDouble(2);

                                availableBalance = accountBalance - holds;
                            }
                        }
                    }
                } catch (SQLException e) {
                    logger.error(e.getMessage(), e);
                }

            } catch (SQLException e) {
                logger.error(e.getMessage(), e);
            }

            return availableBalance;
        });


    }

    private Authorization createAuthorization(String accountNumber, double purchaseAmount, String state) {

        return createAuthorizationTimer.record(() -> {
            Authorization auth = null;

            try (Connection connection = dataSource.getConnection()) {

                connection.setAutoCommit(false);

                int retryCount = 1;

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
                        auth.setLastUpdatedUserId("run-" + region);
                        auth.setState(state);

                        // ACCT_NBR
                        ps.setString(1, auth.getAccountNumber());

                        // REQUEST_ID
                        ps.setObject(2, auth.getRequestId());

                        // AUTH_ID
                        ps.setString(3, auth.getAuthorizationId());

                        // AUTH_AMT
                        ps.setBigDecimal(4, auth.getAuthorizationAmount());

                        // AUTH_STAT_CD
                        ps.setInt(5, auth.getAuthorizationStatus());

                        // CRT_TS
                        ps.setTimestamp(6, auth.getCreatedTimestamp());

                        // LAST_UPD_TS
                        ps.setTimestamp(7, auth.getLastUpdatedTimestamp());

                        // LAST_UPD_USER_ID
                        ps.setString(8, auth.getLastUpdatedUserId());

                        // STATE
                        ps.setString(9, auth.getState());

                        ps.executeUpdate();

                        connection.releaseSavepoint(sp);

                        connection.commit();

                        break;

                    } catch (SQLException e) {

                        String sqlState = e.getSQLState();

                        if (RETRY_SQL_STATE.equals(sqlState)) {
                            logger.warn("attempt " + retryCount + ": will rollback; " + e.getMessage(), e);

                            connection.rollback(sp);

                            insertRetryCounter.incrementAndGet();

                            retryCount++;
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
        });
    }


    private void updateRecords(Authorization authorization, double newBalance) {

        updateRecordsTimer.record(() -> {
            try (Connection connection = dataSource.getConnection()) {

                Timestamp now = new Timestamp(System.currentTimeMillis());

                connection.setAutoCommit(false);

                int retryCount = 1;

                while (true) {

                    Savepoint sp = connection.setSavepoint(SAVEPOINT);

                    try {

                        try (PreparedStatement ps = connection.prepareStatement(UPDATE_AUTHORIZATION_SQL)) {
                            ps.setInt(1, 1);
                            ps.setTimestamp(2, now);
                            ps.setString(3, authorization.getLastUpdatedUserId());
                            ps.setString(4, authorization.getAccountNumber());
                            ps.setString(5, authorization.getState());
                            ps.setObject(6, authorization.getRequestId());

                            ps.executeUpdate();
                        }

                        now = new Timestamp(System.currentTimeMillis());

                        try (PreparedStatement ps = connection.prepareStatement(UPDATE_ACCOUNT_SQL)) {
                            ps.setBigDecimal(1, new BigDecimal(newBalance));
                            ps.setTimestamp(2, now);
                            ps.setString(3, authorization.getLastUpdatedUserId());
                            ps.setString(4, authorization.getAccountNumber());
                            ps.setString(5, authorization.getState());

                            ps.executeUpdate();
                        }

                        connection.releaseSavepoint(sp);

                        connection.commit();

                        break;

                    } catch (SQLException e) {
                        String sqlState = e.getSQLState();

                        if (RETRY_SQL_STATE.equals(sqlState)) {
                            logger.warn("attempt " + retryCount + ": will rollback; " + e.getMessage(), e);

                            connection.rollback(sp);

                            updateRetryCounter.incrementAndGet();

                            retryCount++;
                        } else {
                            throw e;
                        }
                    }
                }

                connection.setAutoCommit(true);


            } catch (SQLException e) {
                logger.error(e.getMessage(), e);
            }
        });

    }

}
