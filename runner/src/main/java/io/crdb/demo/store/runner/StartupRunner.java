package io.crdb.demo.store.runner;

import io.crdb.demo.store.common.Authorization;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.apache.commons.lang3.RandomStringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.*;
import java.util.UUID;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicLong;


@Component
public class StartupRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(StartupRunner.class);

    private static final String SELECT_AVAILABLE_BALANCE_SQL = "select acct.ACCT_BAL_AMT, SUM(auth.AUTH_AMT) from acct left outer join auth on acct.acct_nbr = auth.acct_nbr and acct.state = auth.state and auth.AUTH_STAT_CD = 0 where acct.acct_nbr = ? and acct.state = ? and acct.ACCT_STAT_CD = 1 group by ACCT_BAL_AMT";

    private static final String INSERT_AUTHORIZATION_SQL = "insert into AUTH(ACCT_NBR, REQUEST_ID, AUTH_ID, AUTH_AMT, AUTH_STAT_CD, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, STATE) values (?, ?, ?, ?, ?, ?, ?, ?, ?)";

    private static final String UPDATE_AUTHORIZATION_SQL = "update AUTH set AUTH_STAT_CD = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ? where ACCT_NBR = ? and STATE = ? and REQUEST_ID = ? and AUTH_STAT_CD = 0";

    private static final String UPDATE_ACCOUNT_SQL = "update ACCT set ACCT_BAL_AMT = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ? where ACCT_NBR = ? and STATE = ? and ACCT_STAT_CD = 1";


    private static final String RUNNER = "RUNNER";
    private static final String RETRY_SQL_STATE = "40001";
    private static final String SAVEPOINT = "cockroach_restart";

    private final DataSource dataSource;

    private final Environment environment;

    private final Timer availableBalanceTimer;
    private final Timer createAuthorizationTimer;
    private final Timer updateRecordsTimer;


    @Autowired
    public StartupRunner(DataSource dataSource, Environment environment, MeterRegistry meterRegistry) {
        this.dataSource = dataSource;
        this.environment = environment;

        availableBalanceTimer = Timer.builder("runner.available_balance")
                .description("query available balance")
                .publishPercentiles(0.5, 0.95, 0.99)
                .publishPercentileHistogram()
                .register(meterRegistry);

        createAuthorizationTimer = Timer.builder("runner.create_auth")
                .description("create authorization")
                .publishPercentiles(0.5, 0.95, 0.99)
                .publishPercentileHistogram()
                .register(meterRegistry);

        updateRecordsTimer = Timer.builder("runner.update_records")
                .description("update records")
                .publishPercentiles(0.5, 0.95, 0.99)
                .publishPercentileHistogram()
                .register(meterRegistry);
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        if (args.containsOption("run")) {
            runTests();
        }
    }

    private void runTests() {

        String locality = environment.getRequiredProperty("crdb.locality");
        int duration = environment.getRequiredProperty("crdb.run.duration", Integer.class);

        logger.info("running tests for [{}] minutes with locality as [{}]", duration, locality);

        runTests(locality, duration);

    }

    private void runTests(String locality, int duration) {

        final int threadCount = Runtime.getRuntime().availableProcessors();

        logger.info("starting ExecutorService with {} threads", threadCount);

        final ExecutorService poolService = Executors.newFixedThreadPool(threadCount);

        double purchaseAmount = 5.00;

        final CountDownLatch countDownLatch = new CountDownLatch(threadCount);

        int counter = 0;

        AtomicLong transactions = new AtomicLong(0);

        int accounts = environment.getRequiredProperty("crdb.accts", Integer.class);

        logger.info("upper limit for random account number is {}", accounts);

        while (counter < threadCount) {

            poolService.execute(() -> {

                for (long stop = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(duration); stop > System.currentTimeMillis(); ) {

                    final int random = ThreadLocalRandom.current().nextInt(1, accounts);

                    String accountNumber = locality + "-" + String.format("%022d", random);

                    logger.debug("running test for account number [{}]", accountNumber);

                    Double availableBalance = getAvailableBalance(accountNumber, locality);

                    // for now we are ignoring balance
                    Authorization authorization = createAuthorization(accountNumber, purchaseAmount, locality);

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

            //logger.trace("available balance for [{}] is {}", accountNumber, availableBalance);

            return availableBalance;
        });


    }

    private Authorization createAuthorization(String accountNumber, double purchaseAmount, String locality) {

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
                        auth.setLastUpdatedUserId(RUNNER);
                        auth.setState(locality);

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

                        final int updateCount = ps.executeUpdate();

                        connection.releaseSavepoint(sp);

                        connection.commit();

                        //logger.trace("attempt {}: {} records created in authorization table for account {} and locality {}", retryCount, updateCount, accountNumber, locality);

                        break;

                    } catch (SQLException e) {

                        String sqlState = e.getSQLState();

                        if (RETRY_SQL_STATE.equals(sqlState)) {
                            logger.warn("attempt " + retryCount + ": will rollback; " + e.getMessage(), e);

                            connection.rollback(sp);
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

                        //logger.trace("attempt {}: update to accounts is complete", retryCount);

                        break;

                    } catch (SQLException e) {
                        String sqlState = e.getSQLState();

                        if (RETRY_SQL_STATE.equals(sqlState)) {
                            logger.warn("attempt " + retryCount + ": will rollback; " + e.getMessage(), e);

                            connection.rollback(sp);
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
