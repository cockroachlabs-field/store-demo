package io.crdb.demo.store;

import com.github.javafaker.Faker;
import org.apache.commons.lang3.RandomStringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.util.StopWatch;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.sql.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.Locale;
import java.util.StringJoiner;


@Component
public class StartupRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(StartupRunner.class);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private Environment environment;


    @Override
    public void run(ApplicationArguments args) throws Exception {
        logger.info("Your application started with option names : {}", args.getOptionNames());


        if (args.containsOption("load")) {

            final Integer acctRowCount = environment.getProperty("table.acct.row-count", Integer.class);
            final Integer authRowCount = environment.getProperty("table.auth.row-count", Integer.class);
            final Integer batchSize = environment.getProperty("loader.batch.size", Integer.class);

            logger.debug("loading {} acct records and {} auth records", acctRowCount, authRowCount);

            final String acctInsert = "insert into ACCT(ACCT_NBR, ACCT_TYPE_IND, ACCT_BAL_AMT, ACCT_STAT_CD, EXPIR_DT, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, ACTVT_INQ_TS, ZIPCODE) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";


            try (BufferedWriter writer = new BufferedWriter(new FileWriter("acct-" + acctRowCount + ".txt", true))) {


                Faker faker = new Faker(new Locale("en-US"));

                final Date start = Date.valueOf(LocalDate.of(1980, 01, 01));
                final Date end = Date.valueOf(LocalDate.now());

                // 2016-01-25 10:10:10.555555-05:00
                final DateFormat TIMESTAMP_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
                final DateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd");

                StopWatch sw = new StopWatch();
                sw.start();

                for (int i = 0; i < acctRowCount; i++) {

                    StringJoiner joiner = new StringJoiner("|");
                    joiner.add(RandomStringUtils.randomAlphanumeric(25));
                    joiner.add("HD");
                    joiner.add(Double.toString(faker.number().randomDouble(2, 0, 5000)));
                    joiner.add("1");
                    joiner.add(DATE_FORMAT.format(faker.date().between(start, end)));
                    joiner.add(TIMESTAMP_FORMAT.format(faker.date().between(start, end)));
                    joiner.add(TIMESTAMP_FORMAT.format(faker.date().between(start, end)));
                    joiner.add(RandomStringUtils.randomAlphanumeric(8));
                    joiner.add(TIMESTAMP_FORMAT.format(faker.date().between(start, end)));
                    joiner.add(faker.address().zipCode());

                    writer.write(joiner.toString() + "\n");

                }

                sw.stop();

                logger.debug("finished generating data for table {}: {}", "acct", sw.prettyPrint());

            }
/*
            jdbcTemplate.batchUpdate(acctInsert, new BatchPreparedStatementSetter() {
                @Override
                public void setValues(PreparedStatement ps, int i) throws SQLException {
                    ps.setInt(1, employees.get(i).getId());
                    ps.setString(2, employees.get(i).getFirstName());
                    ps.setString(3, employees.get(i).getLastName());
                    ps.setString(4, employees.get(i).getAddress();
                }

                @Override
                public int getBatchSize() {
                    return batchSize;
                }
            });*/


        }

    }
}
