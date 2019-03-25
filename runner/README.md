# Store Demo - Runner
This Spring Boot application is used to generate load on the CockroachDB cluster.  A `runner` should be deployed in each region you want to test.

The `runner` is designed to simulate purchases with something like a store "credit" card.  For each "swipe" of the card, the following occurs:
* The customers account balance is queried based on account number.
* A "hold" is placed on the account by inserting an authorization record into the `auth` table for the purchase amount.
* The authorization record is updated with an approved status.
* The account record is updated with the new balance.

To start the test run the following:
```
java -jar runner-2019.1-BETA.jar --run
```

The following parameters must be specified as either arguments or in the appropriate `*.properties` file

* `crdb.state` - The state code that this `runner` will use to query database.  For best performance the `crdb.state` should map to `crdb.region`.
* `crdb.region` - The region where this `runner` is located.
* `crdb.servers` - A comma separated list of ip address' or hostname's of a CockroachDB nodes in region. Preferably a private ip address' to prevent external routing.
* `crdb.run.duration` - The duration in minutes this `runner` should generate load.
* `crdb.run.threads` - The number of concurrent threads used to generate load.
* `crdb.accts.total` - The total number of records in the `acct` table
* `crdb.accts.states` - The number of states that `crdb.accts.total` is divided among


