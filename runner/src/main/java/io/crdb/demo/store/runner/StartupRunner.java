package io.crdb.demo.store.runner;

import io.crdb.demo.store.common.Authorization;
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
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;


@Component
public class StartupRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(StartupRunner.class);

    private static final String SELECT_AVAILABLE_BALANCE_SQL = "select acct.ACCT_BAL_AMT, SUM(auth.AUTH_AMT) from acct left outer join auth on acct.acct_nbr = auth.acct_nbr and auth.AUTH_STAT_CD = 0 where acct.acct_nbr = ? and acct.ACCT_STAT_CD = 1 group by ACCT_BAL_AMT";

    // todo: just grabbing first 1000 accounts, may need to add more logic here
    private static final String SELECT_ACCOUNT_NUMBERS_SQL = "select ACCT_NBR from ACCT where STATE = ? limit 1000";

    private static final String INSERT_AUTHORIZATION_SQL = "insert into AUTH(ACCT_NBR, REQUEST_ID, AUTH_ID, AUTH_AMT, AUTH_STAT_CD, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, STATE) values (?, ?, ?, ?, ?, ?, ?, ?, ?)";

    private static final String UPDATE_AUTHORIZATION_SQL = "update AUTH set AUTH_STAT_CD = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ? where ACCT_NBR = ? and REQUEST_ID = ? and AUTH_STAT_CD = 0";

    private static final String UPDATE_ACCOUNT_SQL = "update ACCT set ACCT_BAL_AMT = ?, LAST_UPD_TS = ?, LAST_UPD_USER_ID = ? where ACCT_NBR = ? and ACCT_STAT_CD = 1";


    private static final String RUNNER = "RUNNER";

    @Autowired
    private DataSource dataSource;

    @Autowired
    private Environment environment;


    @Override
    public void run(ApplicationArguments args) throws Exception {
        if (args.containsOption("run")) {
            runTests();
        }
    }

    private void runTests() {

        String locality = environment.getProperty("crdb.locality");

        if (locality == null) {
            throw new IllegalArgumentException("no locality specified for test.  Set \"--crdb.locality\" at startup");
        }

        List<String> accountNumbers = getAccountNumbers(locality);

        logger.debug("returned {} accounts for this test with locality = {}", accountNumbers.size(), locality);

        if (accountNumbers.size() == 0) {
            logger.warn("unable to find any account numbers for locality {}", locality);
        }

        runTests(accountNumbers, locality);

    }

    private List<String> getAccountNumbers(String locality) {
        List<String> accountNumbers = new ArrayList<>();

        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement(SELECT_ACCOUNT_NUMBERS_SQL)) {

            ps.setString(1, locality);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs != null) {
                    while (rs.next()) {
                        accountNumbers.add(rs.getString(1));
                    }
                }
            }

        } catch (SQLException e) {
            logger.error(e.getMessage(), e);
        }
        return accountNumbers;
    }

    private void runTests(List<String> accountNumbers, String locality) {

        for (String accountNumber : accountNumbers) {

            double purchaseAmount = 5.00;

            Double availableBalance = getAvailableBalance(accountNumber);

            // for now we are ignoring balance
            Authorization authorization = createAuthorization(accountNumber, purchaseAmount, locality);

            if (availableBalance < purchaseAmount) {
                logger.warn("available balance is not sufficient {} for purchase amount {}", availableBalance, purchaseAmount);
            }

            double newBalance = availableBalance - purchaseAmount;

            updateRecords(authorization, newBalance);

        }

    }


    private double getAvailableBalance(String accountNumber) {
        double availableBalance = 0.0;

        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement(SELECT_AVAILABLE_BALANCE_SQL)) {

            ps.setString(1, accountNumber);

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

        logger.debug("available balance for [{}] is {}", accountNumber, availableBalance);

        return availableBalance;
    }

    private Authorization createAuthorization(String accountNumber, double purchaseAmount, String locality) {
        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement(INSERT_AUTHORIZATION_SQL)) {

            final Timestamp now = new Timestamp(System.currentTimeMillis());

            Authorization auth = new Authorization();
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

            logger.debug("{} records created in authorization table for account {} and locality {}", updateCount, accountNumber, locality);

            return auth;

        } catch (SQLException e) {
            logger.error(e.getMessage(), e);
        }

        return null;
    }


    private void updateRecords(Authorization authorization, double newBalance) {
        try (Connection connection = dataSource.getConnection()) {

            Timestamp now = new Timestamp(System.currentTimeMillis());

            try (PreparedStatement ps = connection.prepareStatement(UPDATE_AUTHORIZATION_SQL)) {
                ps.setInt(1, 1);
                ps.setTimestamp(2, now);
                ps.setString(3, authorization.getLastUpdatedUserId());
                ps.setString(4, authorization.getAccountNumber());
                ps.setObject(5, authorization.getRequestId());

                ps.executeUpdate();
            }

            now = new Timestamp(System.currentTimeMillis());

            try (PreparedStatement ps = connection.prepareStatement(UPDATE_ACCOUNT_SQL)) {
                ps.setBigDecimal(1, new BigDecimal(newBalance));
                ps.setTimestamp(2, now);
                ps.setString(3, authorization.getLastUpdatedUserId());
                ps.setString(4, authorization.getAccountNumber());

                ps.executeUpdate();
            }

            logger.debug("update to accounts is complete");


        } catch (SQLException e) {
            logger.error(e.getMessage(), e);
        }
    }

}
