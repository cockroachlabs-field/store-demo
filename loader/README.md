# Store Demo - Loader

--create --crdb.server=PRIVATE_IP_OF_IN-REGION_NODE --crdb.accts=PORTION_OF_TOTAL --crdb.auths=PORTION_OF_TOTAL --crdb.locality=STATE


## for the east
scp loader-2019.1-BETA.jar timveil@35.196.10.62:~/



java -jar loader-2019.1-BETA.jar --create --crdb.server=10.142.0.3 --crdb.port=26257 --crdb.accts=150000000 --crdb.auths=3000000 --crdb.locality=SC

timings for 150m & 300k; whoops
```
created 150000000 acct records and 300008 auth records in 1130.576 seconds
```

java -jar loader-2019.1-BETA.jar --load --crdb.server=10.142.0.3 --crdb.port=26257


### for the west

10.168.0.2

java -jar loader-2019.1-BETA.jar --create --crdb.server=10.168.0.2 --crdb.port=26257 --crdb.accts=150000000 --crdb.auths=3000000 --crdb.locality=CA

