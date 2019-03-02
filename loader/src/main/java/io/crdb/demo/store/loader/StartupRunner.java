package io.crdb.demo.store.loader;

import com.github.javafaker.Faker;
import com.google.common.base.Joiner;
import com.google.common.base.Splitter;
import org.apache.commons.lang3.RandomStringUtils;
import org.apache.commons.lang3.StringUtils;
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

    private static final String DATE_PATTERN = "yyyy-MM-dd";
    private static final DateFormat DATE_FORMAT = new SimpleDateFormat(DATE_PATTERN);
    private static final String ACCT_GZ = "acct.gz";
    private static final String AUTH_GZ = "auth.gz";
    private static final String USER_ID = "LOADER";

    @Autowired
    private DataSource dataSource;

    @Autowired
    private Environment environment;


    @Override
    public void run(ApplicationArguments args) throws Exception {
        logger.info("Your application started with option names : {}", args.getOptionNames());


        if (args.containsOption("create")) {
            createData();
        }

        if (args.containsOption("load")) {
            loadAccount();
            loadAuthorization();
        }

    }

    private void createData() throws IOException {
        final int acctRowCount = environment.getProperty("table.acct.row-count", Integer.class, 1000000);
        final int authRowCount = environment.getProperty("table.auth.row-count", Integer.class, 1000);

        logger.debug("creating {} acct records and {} auth records", acctRowCount, authRowCount);

        File acctFile = new File(ACCT_GZ);

        if (acctFile.exists()) {
            final boolean deleted = acctFile.delete();
            logger.debug("deleted file {}: {}", ACCT_GZ, deleted);
        }

        try (FileOutputStream acctOut = new FileOutputStream(ACCT_GZ);
             Writer acctWriter = new OutputStreamWriter(new GZIPOutputStream(acctOut), StandardCharsets.UTF_8)) {

            Faker faker = new Faker(new Locale("en-US"));

            final Date start = Date.valueOf(LocalDate.of(1980, 1, 1));
            final Date end = Date.valueOf(LocalDate.now());

            StopWatch sw = new StopWatch();
            sw.start();

            int authTotalCount = 0;
            int acctTotalCount = 0;

            File authFile = new File(AUTH_GZ);

            if (authFile.exists()) {
                final boolean deleted = authFile.delete();
                logger.debug("deleted file {}: {}", AUTH_GZ, deleted);
            }

            try (FileOutputStream authOut = new FileOutputStream(AUTH_GZ);
                 Writer authWriter = new OutputStreamWriter(new GZIPOutputStream(authOut), StandardCharsets.UTF_8)) {

                for (int ac = 0; ac < acctRowCount; ac++) {

                    final java.util.Date createdDate = faker.date().between(start, end);

                    // ACCT_NBR
                    final String accountNumber = RandomStringUtils.randomAlphanumeric(25);

                    // ACCT_TYPE_IND
                    final String type = "HD";

                    // ACCT_BAL_AMT - we are going to just initialize every account with a $100 balance, may get updated
                    double balance = faker.number().randomDouble(2, 0, 1000);

                    // ACCT_STAT_CD
                    final String status = "1";

                    // EXPIR_DT
                    final String expirationDate = null;

                    // CRT_TS
                    final String createdTimestamp = TIMESTAMP_FORMAT.format(createdDate);

                    // LAST_UPD_TS
                    String lastUpdatedTimestamp = null;

                    // LAST_UPD_USER_ID
                    String lastUpdatedUserId = null;

                    // ACTVT_INQ_TS
                    String lastBalanceInquiry = null;

                    // STATE
                    final String state = faker.address().stateAbbr();


                    if (authTotalCount < authRowCount) {

                        if (faker.random().nextBoolean()) {

                            int count = faker.random().nextInt(1, 10);

                            java.util.Date authorizationCreatedTS = null;

                            for (int au = 0; au < count; au++) {

                                // REQUEST_ID
                                final String requestId = UUID.randomUUID().toString();

                                // AUTH_ID
                                final String authorizationId = RandomStringUtils.randomAlphanumeric(64);

                                // AUTH_AMT - for simplicity we are always going authorize $5
                                final double authorizationAmount = faker.number().randomDouble(2, 1, 100);

                                // AUTH_STAT_CD - if 1 apply to balance, if 0 its a hold

                                final boolean applyBalance = faker.random().nextBoolean();

                                String authorizationStatus;

                                if (applyBalance) {
                                    authorizationStatus = "1";
                                    balance -= authorizationAmount;
                                } else {
                                    authorizationStatus = "0";
                                }

                                // CRT_TS
                                if (authorizationCreatedTS == null) {
                                    authorizationCreatedTS = faker.date().between(createdDate, end);
                                } else {
                                    authorizationCreatedTS = faker.date().between(authorizationCreatedTS, end);
                                }

                                final String authorizationCreatedTimestamp = TIMESTAMP_FORMAT.format(authorizationCreatedTS);

                                // LAST_UPD_TS
                                final String authorizationLastUpdatedTimestamp = TIMESTAMP_FORMAT.format(authorizationCreatedTS);

                                // LAST_UPD_USER_ID
                                final String authorizationLastUpdatedUserId = USER_ID;

                                final String auth = Joiner.on('|').useForNull("")
                                        .join(accountNumber,
                                                requestId,
                                                authorizationId,
                                                authorizationAmount,
                                                authorizationStatus,
                                                authorizationCreatedTimestamp,
                                                authorizationLastUpdatedTimestamp,
                                                authorizationLastUpdatedUserId,
                                                state);

                                authTotalCount++;

                                authWriter.write(auth + '\n');
                            }

                            lastBalanceInquiry = TIMESTAMP_FORMAT.format(authorizationCreatedTS);
                            lastUpdatedTimestamp = TIMESTAMP_FORMAT.format(authorizationCreatedTS);
                            lastUpdatedUserId = USER_ID;
                        }
                    }

                    final String account = Joiner.on('|').useForNull("")
                            .join(accountNumber,
                                    type,
                                    balance,
                                    status,
                                    expirationDate,
                                    createdTimestamp,
                                    lastUpdatedTimestamp,
                                    lastUpdatedUserId,
                                    lastBalanceInquiry,
                                    state);

                    acctTotalCount++;

                    if (acctTotalCount != 0 && (acctTotalCount % 10000) == 0) {
                        // coarse grained tracker
                        logger.info("created {} records", acctTotalCount);
                    }

                    acctWriter.write(account + '\n');
                }
            }

            sw.stop();

            logger.info("created {} acct records and {} auth records in {} seconds", acctTotalCount, authTotalCount, sw.getTotalTimeSeconds());

        }
    }

    private void loadAccount() throws SQLException, IOException, ParseException {
        StopWatch sw = new StopWatch("load acct");
        sw.start();

        final String acctInsert = "insert into ACCT(ACCT_NBR, ACCT_TYPE_IND, ACCT_BAL_AMT, ACCT_STAT_CD, EXPIR_DT, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, ACTVT_INQ_TS, STATE) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        final int batchSize = environment.getProperty("loader.batch.size", Integer.class, 128);

        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement(acctInsert)) {

            try (GZIPInputStream gzip = new GZIPInputStream(new FileInputStream(ACCT_GZ));
                 BufferedReader br = new BufferedReader(new InputStreamReader(gzip))) {

                String line;

                int i = 0;
                while ((line = br.readLine()) != null) {
                    final List<String> columns = Splitter.on('|').trimResults().splitToList(line);

                    // ACCT_NBR
                    ps.setString(1, columns.get(0));

                    // ACCT_TYPE_IND
                    ps.setString(2, columns.get(1));

                    // ACCT_BAL_AMT
                    ps.setBigDecimal(3, new BigDecimal(columns.get(2)));

                    // ACCT_STAT_CD
                    ps.setInt(4, Integer.parseInt(columns.get(3)));

                    // EXPIR_DT
                    final String expirationDate = columns.get(4);
                    if (StringUtils.isNotBlank(expirationDate)) {
                        ps.setDate(5, new java.sql.Date(DATE_FORMAT.parse(expirationDate).getTime()));
                    } else {
                        ps.setDate(5, null);
                    }

                    // CRT_TS
                    ps.setTimestamp(6, new Timestamp(TIMESTAMP_FORMAT.parse(columns.get(5)).getTime()));

                    // LAST_UPD_TS
                    final String lastUpdatedTimestamp = columns.get(6);
                    if (StringUtils.isNotBlank(lastUpdatedTimestamp)) {
                        ps.setTimestamp(7, new Timestamp(TIMESTAMP_FORMAT.parse(lastUpdatedTimestamp).getTime()));
                    } else {
                        ps.setTimestamp(7, null);
                    }

                    // LAST_UPD_USER_ID
                    final String lastUpdatedUserId = columns.get(7);
                    if (StringUtils.isNotBlank(lastUpdatedUserId)) {
                        ps.setString(8, lastUpdatedUserId);
                    } else {
                        ps.setString(8, null);
                    }

                    // ACTVT_INQ_TS
                    final String inquiryTimestamp = columns.get(8);
                    if (StringUtils.isNotBlank(inquiryTimestamp)) {
                        ps.setTimestamp(9, new Timestamp(TIMESTAMP_FORMAT.parse(inquiryTimestamp).getTime()));
                    } else {
                        ps.setTimestamp(9, null);
                    }

                    // STATE
                    ps.setString(10, columns.get(9));

                    ps.addBatch();

                    if (i != 0 && (i % batchSize) == 0) {
                        ps.executeBatch();
                        logger.debug("loaded ACCT batch {}", i);
                    }

                    if (i != 0 && (i % 10000) == 0) {
                        // coarse grained tracker
                        logger.info("loaded {} Accounts", i);
                    }

                    i++;
                }
            }

            ps.executeBatch();

            logger.debug("loaded remaining");

        }

        sw.stop();
        logger.info(sw.prettyPrint());
    }

    private void loadAuthorization() throws SQLException, IOException, ParseException {
        StopWatch sw = new StopWatch("load auth");
        sw.start();

        final String acctInsert = "insert into AUTH(ACCT_NBR, REQUEST_ID, AUTH_ID, AUTH_AMT, AUTH_STAT_CD, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, STATE) values (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        final int batchSize = environment.getProperty("loader.batch.size", Integer.class, 128);

        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement(acctInsert)) {

            try (GZIPInputStream gzip = new GZIPInputStream(new FileInputStream(AUTH_GZ));
                 BufferedReader br = new BufferedReader(new InputStreamReader(gzip))) {

                String line;

                int i = 0;
                while ((line = br.readLine()) != null) {
                    final List<String> columns = Splitter.on('|').trimResults().splitToList(line);

                    // ACCT_NBR
                    ps.setString(1, columns.get(0));

                    // REQUEST_ID
                    ps.setObject(2, UUID.fromString(columns.get(1)));

                    // AUTH_ID
                    ps.setString(3, columns.get(2));

                    // AUTH_AMT
                    ps.setBigDecimal(4, new BigDecimal(columns.get(3)));

                    // AUTH_STAT_CD
                    ps.setInt(5, Integer.parseInt(columns.get(4)));

                    // CRT_TS
                    ps.setTimestamp(6, new Timestamp(TIMESTAMP_FORMAT.parse(columns.get(5)).getTime()));

                    // LAST_UPD_TS
                    ps.setTimestamp(7, new Timestamp(TIMESTAMP_FORMAT.parse(columns.get(6)).getTime()));

                    // LAST_UPD_USER_ID
                    ps.setString(8, columns.get(7));

                    // STATE
                    ps.setString(9, columns.get(8));

                    ps.addBatch();

                    if (i != 0 && (i % batchSize) == 0) {
                        ps.executeBatch();
                        logger.debug("loaded AUTH batch {}", i);
                    }

                    if (i != 0 && (i % 10000) == 0) {
                        // coarse grained tracker
                        logger.info("loaded {} Authorizations", i);
                    }

                    i++;
                }
            }

            ps.executeBatch();

            logger.debug("loaded remaining");

        }

        sw.stop();
        logger.info(sw.prettyPrint());
    }
}
