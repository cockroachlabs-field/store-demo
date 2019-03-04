# Store Demo - Loader

This Spring Boot application is used to generate test data files and load data into the `store_demo` database.

## Generating Data
To generate data run the following command:

```bash
java -jar loader-2019.1-BETA.jar --generate
```

`generate` accepts the following additional parameters:
* `crdb.localities` - a comma separated list of "states" to generate data for. These "states" should map to partitions which will in turn be used in zone constaints 
* `crdb.accts` - number of records to create for the `acct` table
* `crdb.auths` - number of records to create for the `auth` table

For example, this command would result in the creation of 2 files `accts-1000.csv` and `auths-100.csv` in current directory.  These files can be used for future `load` or `import` commands.
```bash
java -jar loader-2019.1-BETA.jar --generate --crdb.localities=SC,TX,CA --crdb.accts=1000 --crdb.auths=100
```

## Import Data via Import Command (preferred)
An alternative method for loading large amounts of data quickly can be used.  To use this option run the following:
```bash
java -jar loader-2019.1-BETA.jar --import
```

`import` accepts the following additional parameters:
* `crdb.accts.create.url` - url of sql file to create `acct` table
* `crdb.accts.data.url` - url of `.csv` file to load into `acct` table
* `crdb.auths.create.url` - url of sql file to create `auth` table
* `crdb.auths.data.url` - url of `.csv` file to load into `auth` table
* `crdb.server` - the ip address or hostname of a CockroachDB node

## Import Data via JDBC Batch Insert
To `generate` data files and immediately `load` them into the database using batch statements you can run the following:
```bash
java -jar loader-2019.1-BETA.jar --generate --load
```

`load` accepts the following additional parameters:
* `crdb.accts.data.file` - path to `.csv` for loading `acct` table
* `crdb.auths.data.file` - path to `.csv` for loading `auth` table
* `crdb.server` - the ip address or hostname of a CockroachDB node
