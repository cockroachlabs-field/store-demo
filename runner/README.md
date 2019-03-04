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

* `crdb.locality` - The state code that this `runner` will use to query database.  For best performance the `crdb.locality` will match the "region".
* `crdb.server` - The ip address or hostname of a CockroachDB node in region. Preferably a private ip address to prevent external routing.
* `crdb.run.duration` - The duration in minutes this `runner` should generate load.
* `crdb.run.threads` - The number of concurrent threads used to generate load.
* `crdb.accts` - A number less than or equal to the # of accounts that match the records in this `crdb.locality`.  Used as the upper bound of a random number generator to find valid account numbers to be used during testing.


