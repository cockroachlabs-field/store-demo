package io.crdb.demo.store.runner;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;


@Component
public class StartupRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(StartupRunner.class);

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

        runTests(accountNumbers);

    }

    private List<String> getAccountNumbers(String locality) {
        List<String> accountNumbers = new ArrayList<>();

        // todo: just grabbing first 1000 accounts, may need to add more logic here
        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement("select ACCT_NBR from ACCT where STATE = ? limit 1000")) {

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

    private void runTests(List<String> accountNumbers) {

        for (String accountNumber : accountNumbers) {

            String availableBalanceSQL = "select acct.ACCT_BAL_AMT, SUM(auth.AUTH_AMT) from acct left outer join auth on acct.acct_nbr = auth.acct_nbr and auth.AUTH_STAT_CD = 0 where acct.acct_nbr = ? and acct.ACCT_STAT_CD = 1 group by ACCT_BAL_AMT";

            Double availableBalance = null;


            try (Connection connection = dataSource.getConnection();
                 PreparedStatement ps = connection.prepareStatement(availableBalanceSQL)) {

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


            /*
            // This will always return 0 or 1 rows.  Note: ACCT_BAL_AMT can be negative.
SELECT ACCT_BAL_AMT
FROM ACCT
WHERE
  ACCT_NBR = ?
  AND ACCT_STAT_CD = 1;

// This query returns the sum of funds currently on hold, but not applied to the account balance yet.
SELECT SUM(AUTH_AMT)
FROM AUTH
WHERE
  ACCT_NBR = ?
  AND AUTH_STAT_CD = 0;

             */

        }

    }


}
