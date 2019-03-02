# Store Demo - Loader

--create --crdb.server=PRIVATE_IP_OF_IN-REGION_NODE --crdb.accts=PORTION_OF_TOTAL --crdb.auths=PORTION_OF_TOTAL --crdb.locality=STATE

--generate
--load
--crdb.server
--crdb.port
--crdb.accts
--crdb.accts.data.file
--crdb.auths
--crdb.auths.data.file
--crdb.localities


## for the east
scp loader-2019.1-BETA.jar timveil@35.196.10.62:~/



java -jar loader-2019.1-BETA.jar --create --crdb.server=10.142.0.3

timings for 150m & 300k; whoops
```
created 150000000 acct records and 300008 auth records in 1130.576 seconds
```

java -jar loader-2019.1-BETA.jar --load --crdb.server=10.142.0.3

