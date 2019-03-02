# Store Demo - Loader

--generate
--load
--crdb.server

## for the east
scp loader-2019.1-BETA.jar timveil@35.196.10.62:~/



java -jar loader-2019.1-BETA.jar --create --crdb.server=10.142.0.3

timings for 150m & 300k; whoops
```
created 150000000 acct records and 300008 auth records in 1130.576 seconds
```

java -jar loader-2019.1-BETA.jar --load --crdb.server=10.142.0.3

