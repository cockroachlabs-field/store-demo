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

    }

    private List<String> getAccountNumbers(String locality) {
        List<String> accountNumbers = new ArrayList<>();

        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement("select ACCT_NBR from ACCT where ZIPCODE = ? limit 1000")) {

            ps.setString(1, locality);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs != null) {
                    while (rs.next()) {
                        accountNumbers.add(rs.getString("1"));
                    }
                }
            }

        } catch (SQLException e) {
            logger.error(e.getMessage(), e);
        }
        return accountNumbers;
    }


}
