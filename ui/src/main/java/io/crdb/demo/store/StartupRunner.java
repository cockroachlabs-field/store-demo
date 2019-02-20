package io.crdb.demo.store;

import com.github.javafaker.Faker;
import com.google.common.base.Joiner;
import com.google.common.base.Splitter;
import org.apache.commons.lang3.RandomStringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.util.StopWatch;

import javax.sql.DataSource;
import java.io.*;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;


@Component
public class StartupRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(StartupRunner.class);
    private static final String TIMESTAMP_PATTERN = "yyyy-MM-dd HH:mm:ss";
    private static final DateFormat TIMESTAMP_FORMAT = new SimpleDateFormat(TIMESTAMP_PATTERN);
    private static final String ACCT_GZ = "acct.gz";
    private static final String AUTH_GZ = "auth.gz";

    @Autowired
    private DataSource dataSource;

    @Autowired
    private Environment environment;


    @Override
    public void run(ApplicationArguments args) throws Exception {
        logger.info("Your application started with option names : {}", args.getOptionNames());


        if (args.containsOption("create")) {
            createRecords();
        }

        if (args.containsOption("load")) {
            loadAccount();
            loadAuthorization();
        }

    }

    private void loadAccount() throws SQLException, IOException, ParseException {
        StopWatch sw = new StopWatch("load acct");
        sw.start();

        final String acctInsert = "insert into ACCT(ACCT_NBR, ACCT_TYPE_IND, ACCT_BAL_AMT, ACCT_STAT_CD, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, ACTVT_INQ_TS, ZIPCODE) values (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        final Integer batchSize = environment.getProperty("loader.batch.size", Integer.class);

        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement(acctInsert)) {

            try (GZIPInputStream gzip = new GZIPInputStream(new FileInputStream(ACCT_GZ));
                 BufferedReader br = new BufferedReader(new InputStreamReader(gzip))) {

                String line;

                int i = 0;
                while ((line = br.readLine()) != null) {
                    final List<String> columns = Splitter.on('|').trimResults().splitToList(line);

                    ps.setString(1, columns.get(0));
                    ps.setString(2, columns.get(1));
                    ps.setBigDecimal(3, new BigDecimal(columns.get(2)));
                    ps.setInt(4, Integer.parseInt(columns.get(3)));
                    ps.setTimestamp(5, new Timestamp(TIMESTAMP_FORMAT.parse(columns.get(4)).getTime()));
                    ps.setTimestamp(6, new Timestamp(TIMESTAMP_FORMAT.parse(columns.get(5)).getTime()));
                    ps.setString(7, columns.get(6));
                    ps.setTimestamp(8, new Timestamp(TIMESTAMP_FORMAT.parse(columns.get(7)).getTime()));
                    ps.setString(9, columns.get(8));

                    ps.addBatch();

                    if (i != 0 && (i % batchSize) == 0) {

                        ps.executeBatch();

                        logger.debug("loaded batch {}", i);
                    }

                    i++;
                }
            }

            ps.executeBatch();

            logger.debug("loaded remaining");

        }

        sw.stop();
        logger.debug(sw.prettyPrint());
    }

    private void loadAuthorization() throws SQLException, IOException, ParseException {
        StopWatch sw = new StopWatch("load auth");
        sw.start();

        final String acctInsert = "insert into AUTH(ACCT_NBR, REQUEST_ID, AUTH_ID, AUTH_AMT, AUTH_STAT_CD, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, ZIPCODE) values (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        final Integer batchSize = environment.getProperty("loader.batch.size", Integer.class);

        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement(acctInsert)) {

            try (GZIPInputStream gzip = new GZIPInputStream(new FileInputStream(AUTH_GZ));
                 BufferedReader br = new BufferedReader(new InputStreamReader(gzip))) {

                String line;

                int i = 0;
                while ((line = br.readLine()) != null) {
                    final List<String> columns = Splitter.on('|').trimResults().splitToList(line);

                    ps.setString(1, columns.get(0));
                    ps.setObject(2, UUID.fromString(columns.get(1)));
                    ps.setString(3, columns.get(2));
                    ps.setBigDecimal(4, new BigDecimal(columns.get(3)));
                    ps.setInt(5, Integer.parseInt(columns.get(4)));
                    ps.setTimestamp(6, new Timestamp(TIMESTAMP_FORMAT.parse(columns.get(5)).getTime()));
                    ps.setTimestamp(7, new Timestamp(TIMESTAMP_FORMAT.parse(columns.get(6)).getTime()));
                    ps.setString(8, columns.get(7));
                    ps.setString(9, columns.get(8));

                    ps.addBatch();

                    if (i != 0 && (i % batchSize) == 0) {

                        ps.executeBatch();

                        logger.debug("loaded batch {}", i);
                    }

                    i++;
                }
            }

            ps.executeBatch();

            logger.debug("loaded remaining");

        }

        sw.stop();
        logger.debug(sw.prettyPrint());
    }


    private void createRecords() throws IOException {
        final Integer acctRowCount = environment.getProperty("table.acct.row-count", Integer.class, 1000000);
        final Integer authRowCount = environment.getProperty("table.auth.row-count", Integer.class, 1000);

        logger.debug("creating {} acct records and {} auth records", acctRowCount, authRowCount);

        try (FileOutputStream acctOut = new FileOutputStream(ACCT_GZ);
             Writer acctWriter = new OutputStreamWriter(new GZIPOutputStream(acctOut), StandardCharsets.UTF_8)) {


            Faker faker = new Faker(new Locale("en-US"));

            final Date start = Date.valueOf(LocalDate.of(1980, 01, 01));
            final Date end = Date.valueOf(LocalDate.now());

            StopWatch sw = new StopWatch();
            sw.start();

            int authTotalCount = 0;
            int acctTotalCount = 0;

            try (FileOutputStream authOut = new FileOutputStream(AUTH_GZ);
                 Writer authWriter = new OutputStreamWriter(new GZIPOutputStream(authOut), StandardCharsets.UTF_8)) {


                for (int ac = 0; ac < acctRowCount; ac++) {


                    final String accountNumber = RandomStringUtils.randomAlphanumeric(25);
                    final String type = "HD";
                    final String balance = Double.toString(faker.number().randomDouble(2, -1000, 5000));
                    final String status = "1";
                    final String createdTimestamp = TIMESTAMP_FORMAT.format(faker.date().between(start, end));
                    final String lastUpdatedTimestamp = TIMESTAMP_FORMAT.format(faker.date().between(start, end));
                    final String lastUpdatedUserId = RandomStringUtils.randomAlphanumeric(8);
                    final String lastBalanceInquiry = TIMESTAMP_FORMAT.format(faker.date().between(start, end));
                    final String zipCode = faker.address().zipCode();

                    final String account = Joiner.on('|')
                            .join(accountNumber,
                                    type,
                                    balance,
                                    status,
                                    createdTimestamp,
                                    lastUpdatedTimestamp,
                                    lastUpdatedUserId,
                                    lastBalanceInquiry,
                                    zipCode);


                    acctTotalCount++;

                    acctWriter.write(account + '\n');

                    if (authTotalCount <= authRowCount) {

                        if (ac != 0 && (ac % 100 == 0)) {

                            int count = faker.random().nextInt(1, 10);

                            for (int au = 0; au < count; au++) {

                                final String auth = Joiner.on('|')
                                        .join(accountNumber,
                                                UUID.randomUUID().toString(),
                                                RandomStringUtils.randomAlphanumeric(64),
                                                Double.toString(faker.number().randomDouble(2, 0, 1000)),
                                                Integer.toString(faker.number().numberBetween(0, 2)),
                                                TIMESTAMP_FORMAT.format(faker.date().between(start, end)),
                                                TIMESTAMP_FORMAT.format(faker.date().between(start, end)),
                                                RandomStringUtils.randomAlphanumeric(8),
                                                zipCode);

                                authTotalCount++;

                                authWriter.write(auth + '\n');
                            }
                        }
                    }
                }
            }

            sw.stop();

            logger.debug("created {} acct records and {} auth records in {} seconds", acctTotalCount, authTotalCount, sw.getTotalTimeSeconds());

        }
    }
}
