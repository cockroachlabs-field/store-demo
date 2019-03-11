package io.crdb.demo.store.loader;

import com.github.javafaker.Faker;
import com.google.common.base.Joiner;
import com.google.common.base.Splitter;
import com.google.common.collect.Lists;
import com.google.common.collect.Ordering;
import org.apache.commons.lang3.RandomStringUtils;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import org.springframework.stereotype.Component;
import org.springframework.util.StopWatch;

import javax.sql.DataSource;
import java.io.*;
import java.math.BigDecimal;
import java.sql.*;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.UUID;


@Component
public class LoaderRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(LoaderRunner.class);
    private static final String TIMESTAMP_PATTERN = "yyyy-MM-dd HH:mm:ss";
    private static final DateFormat TIMESTAMP_FORMAT = new SimpleDateFormat(TIMESTAMP_PATTERN);

    private static final String DATE_PATTERN = "yyyy-MM-dd";
    private static final DateFormat DATE_FORMAT = new SimpleDateFormat(DATE_PATTERN);
    private static final String USER_ID = "loader";

    @Value("${crdb.log.batch}")
    private int logBatch;

    private final DataSource dataSource;
    private final Environment environment;
    private final ResourceLoader resourceLoader;

    @Autowired
    public LoaderRunner(DataSource dataSource, Environment environment, ResourceLoader resourceLoader) {
        this.dataSource = dataSource;
        this.environment = environment;
        this.resourceLoader = resourceLoader;
    }

    private class DataFiles {
        private final String accountFile;
        private final String authorizationFile;

        DataFiles(String accountFile, String authorizationFile) {
            this.accountFile = accountFile;
            this.authorizationFile = authorizationFile;
        }

        String getAccountFile() {
            return accountFile;
        }

        String getAuthorizationFile() {
            return authorizationFile;
        }
    }


    @Override
    public void run(ApplicationArguments args) throws Exception {
        logger.info("Your application started with option names : {}", args.getOptionNames());

        DataFiles files = null;

        if (args.containsOption("generate")) {
            files = generateFiles();
        }

        if (args.containsOption("load")) {

            if (files == null) {
                final String acctFileName = environment.getRequiredProperty("crdb.load.accts.data.file");
                final String authFileName = environment.getRequiredProperty("crdb.load.auths.data.file");


                files = new DataFiles(acctFileName, authFileName);
            }

            createSchema();

            Thread.sleep(10000);

            loadAccountFromFile(files);

            loadAuthorizationFromFile(files);

        } else if (args.containsOption("import")) {
            importTables();
        }

    }

    private void importTables() throws SQLException {

        dropTables("ACCT");
        dropTables("AUTH");

        final String acctCreateUrl = environment.getRequiredProperty("crdb.import.accts.create.url");
        final String acctDataUrl = environment.getRequiredProperty("crdb.import.accts.data.url");

        logger.info("acct: url for create [{}], url for data [{}]", acctCreateUrl, acctDataUrl);

        final String importAcct = "IMPORT TABLE ACCT CREATE USING '" + acctCreateUrl + "' CSV DATA ('" + acctDataUrl + "') WITH nullif = '', delimiter = e'\\|'";

        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement(importAcct)) {
            statement.execute();
        }


        final String authCreateUrl = environment.getRequiredProperty("crdb.import.auths.create.url");
        final String authDataUrl = environment.getRequiredProperty("crdb.import.auths.data.url");

        logger.info("auth: url for create [{}], url for data [{}]", authCreateUrl, authDataUrl);

        final String importAuth = "IMPORT TABLE AUTH CREATE USING '" + authCreateUrl + "' CSV DATA ('" + authDataUrl + "') WITH nullif = '', delimiter = e'\\|'";

        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement(importAuth)) {
            statement.execute();
        }

        logger.info("applying zone configs to imported tables");

        try (Connection connection = dataSource.getConnection()) {
            final Resource resource = resourceLoader.getResource("classpath:zone-config.sql");

            ScriptUtils.executeSqlScript(connection, resource);
        }

    }

    private DataFiles generateFiles() throws IOException {
        final int acctRowCount = environment.getRequiredProperty("crdb.generate.accts", Integer.class);

        final int authRowCount = environment.getRequiredProperty("crdb.generate.auths", Integer.class);

        final String origin = environment.getProperty("crdb.generate.origin.state");

        logger.info("generating {} acct records and {} auth records for state {}", acctRowCount, authRowCount, environment.getRequiredProperty("crdb.generate.states"));

        if (StringUtils.isNotBlank(origin)) {
            logger.info("all records will have origin [{}]", origin);
        }

        List<String> states = Ordering.natural().sortedCopy(Splitter.on(',').split(environment.getRequiredProperty("crdb.generate.states")));

        String acctFileName = "accts-" + acctRowCount + ".csv";
        String authFileName = "auths-" + authRowCount + ".csv";

        File acctFile = new File(acctFileName);

        if (acctFile.exists()) {
            final boolean deleted = acctFile.delete();
            logger.debug("deleted file {}: {}", acctFileName, deleted);
        }

        try (BufferedWriter acctWriter = new BufferedWriter(new FileWriter(acctFile))) {

            Faker faker = new Faker(new Locale("en-US"));

            final Date start = Date.valueOf(LocalDate.of(1980, 1, 1));
            final Date end = Date.valueOf(LocalDate.now());

            StopWatch sw = new StopWatch();
            sw.start();

            int authTotalCount = 0;
            int acctTotalCount = 0;

            File authFile = new File(authFileName);

            if (authFile.exists()) {
                final boolean deleted = authFile.delete();
                logger.debug("deleted file {}: {}", authFileName, deleted);
            }

            int accountsPerLocality = acctRowCount / states.size();
            int authorizationsPerLocality = authRowCount / states.size();

            try (BufferedWriter authWriter = new BufferedWriter(new FileWriter(authFile))) {

                for (String state : states) {

                    int authCounter = 0;

                    for (int ac = 0; ac < accountsPerLocality; ac++) {

                        final java.util.Date createdDate = faker.date().between(start, end);

                        // ACCT_NBR
                        final String accountNumber = state + "-" + String.format("%022d", (ac + 1));

                        // ACCT_TYPE_IND
                        final String type = "XX";

                        // ACCT_BAL_AMT - we are going to just initialize every account with a $100 balance, may get updated
                        double balance = 100.00;

                        // ACCT_STAT_CD
                        final String status = "1";

                        // CRT_TS
                        final String createdTimestamp = TIMESTAMP_FORMAT.format(createdDate);

                        // LAST_UPD_TS
                        String lastUpdatedTimestamp = null;

                        // LAST_UPD_USER_ID
                        String lastUpdatedUserId = null;

                        // ACTVT_INQ_TS
                        String lastBalanceInquiry = null;

                        if (authCounter < authorizationsPerLocality) {

                            if (faker.random().nextBoolean()) {

                                int count = faker.random().nextInt(1, 3);

                                java.util.Date authorizationCreatedTS = null;

                                for (int au = 0; au < count; au++) {

                                    // REQUEST_ID
                                    final String requestId = UUID.randomUUID().toString();

                                    // AUTH_ID
                                    final String authorizationId = RandomStringUtils.randomAlphanumeric(64);

                                    // AUTH_AMT - for simplicity we are always going authorize $5.05
                                    final double authorizationAmount = 5.05;

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


                                    final String auth = Joiner.on('|').useForNull("")
                                            .join(accountNumber,
                                                    requestId,
                                                    authorizationId,
                                                    authorizationAmount,
                                                    authorizationStatus,
                                                    authorizationCreatedTimestamp,
                                                    authorizationLastUpdatedTimestamp,
                                                    USER_ID,
                                                    StringUtils.isNotBlank(origin) ? origin : state);

                                    authCounter++;
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
                                        null,
                                        createdTimestamp,
                                        lastUpdatedTimestamp,
                                        lastUpdatedUserId,
                                        lastBalanceInquiry,
                                        StringUtils.isNotBlank(origin) ? origin : state);

                        acctTotalCount++;

                        if (acctTotalCount != 0 && (acctTotalCount % logBatch) == 0) {
                            // coarse grained tracker
                            logger.info("generated {} records", acctTotalCount);
                        }

                        acctWriter.write(account + '\n');
                    }

                }
            }

            sw.stop();

            logger.info("generated {} acct records and {} auth records in {} seconds", acctTotalCount, authTotalCount, sw.getTotalTimeSeconds());

        }

        return new DataFiles(acctFileName, authFileName);
    }

    private void createSchema() throws SQLException {
        try (Connection connection = dataSource.getConnection()) {
            dropTables("ACCT");
            dropTables("AUTH");

            ScriptUtils.executeSqlScript(connection, resourceLoader.getResource("classpath:create-acct.sql"));
            ScriptUtils.executeSqlScript(connection, resourceLoader.getResource("classpath:create-auth.sql"));
            ScriptUtils.executeSqlScript(connection, resourceLoader.getResource("classpath:zone-config.sql"));
        }
    }

    private void loadAccountFromFile(DataFiles files) throws SQLException, IOException, ParseException {
        StopWatch sw = new StopWatch("load acct");
        sw.start();

        final String acctInsert = "insert into ACCT(ACCT_NBR, ACCT_TYPE_IND, ACCT_BAL_AMT, ACCT_STAT_CD, EXPIR_DT, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, ACTVT_INQ_TS, STATE) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        final int batchSize = environment.getRequiredProperty("crdb.load.batch", Integer.class);

        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement(acctInsert)) {

            try (BufferedReader br = new BufferedReader(new FileReader(files.getAccountFile()))) {

                String line;

                int i = 0;
                while ((line = br.readLine()) != null) {
                    final List<String> columns = Lists.newArrayList(Splitter.on('|').trimResults().split(line));

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
                        logger.trace("loaded ACCT batch {}", i);
                    }

                    if (i != 0 && (i % logBatch) == 0) {
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

    private void loadAuthorizationFromFile(DataFiles files) throws SQLException, IOException, ParseException {
        StopWatch sw = new StopWatch("load auth");
        sw.start();

        final String acctInsert = "insert into AUTH(ACCT_NBR, REQUEST_ID, AUTH_ID, AUTH_AMT, AUTH_STAT_CD, CRT_TS, LAST_UPD_TS, LAST_UPD_USER_ID, STATE) values (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        final int batchSize = environment.getRequiredProperty("crdb.load.batch", Integer.class);

        try (Connection connection = dataSource.getConnection();
             PreparedStatement ps = connection.prepareStatement(acctInsert)) {

            try (BufferedReader br = new BufferedReader(new FileReader(files.getAuthorizationFile()))) {

                String line;

                int i = 0;
                while ((line = br.readLine()) != null) {
                    final List<String> columns = Lists.newArrayList(Splitter.on('|').trimResults().split(line));

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
                        logger.trace("loaded AUTH batch {}", i);
                    }

                    if (i != 0 && (i % logBatch) == 0) {
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

    private void dropTables(String tableName) throws SQLException {
        logger.info("dropping {} table", tableName);

        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement("DROP TABLE IF EXISTS " + tableName + " CASCADE")) {
            statement.execute();
        }

    }
}
