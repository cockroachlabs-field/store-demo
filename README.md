# Store Demo
General purpose demo that highlights survivability across Data Centers, Cloud Providers and the Continental U.S. [power transmission grid](https://en.wikipedia.org/wiki/Continental_U.S._power_transmission_grid).

The project contains the following modules:

* [docker](docker/README.md) - for provisioning a local Docker cluster to run the demo
* [terraform](terraform/README.md) - for provisioning a production like cluster in the cloud to run the demo
* [loader](loader/README.md) - Spring Boot application responsible for creating and loading test data
* [runner](runner/README.md) - Spring Boot application responsible for executing the workload

2019-03-05 20:43:14.366  WARN 23167 --- [ool-1-thread-63] io.crdb.demo.store.runner.StartupRunner  : attempt 1: will rollback; ERROR: restart transaction: HandledRetryableTxnError: TransactionRetryError: retry txn (RETRY_ASYNC_WRITE_FAILURE): "sql txn" id=18ad476a key=/Table/56/1/"TX"/"TX-0000000000000008701484"/"\x9e\xb4\xa6\xc5\x1d\x1dE\x0e\xa2\xc4\x10#v\x85\xf7\xd6"/0 rw=true pri=0.03921734 iso=SERIALIZABLE stat=PENDING epo=0 ts=1551818594.264697673,12 orig=1551818594.264697673,12 max=1551818594.266293029,0 wto=false rop=false seq=3

org.postgresql.util.PSQLException: ERROR: restart transaction: HandledRetryableTxnError: TransactionRetryError: retry txn (RETRY_ASYNC_WRITE_FAILURE): "sql txn" id=18ad476a key=/Table/56/1/"TX"/"TX-0000000000000008701484"/"\x9e\xb4\xa6\xc5\x1d\x1dE\x0e\xa2\xc4\x10#v\x85\xf7\xd6"/0 rw=true pri=0.03921734 iso=SERIALIZABLE stat=PENDING epo=0 ts=1551818594.264697673,12 orig=1551818594.264697673,12 max=1551818594.266293029,0 wto=false rop=false seq=3
	at org.postgresql.core.v3.QueryExecutorImpl.receiveErrorResponse(QueryExecutorImpl.java:2440) ~[postgresql-42.2.5.jar!/:42.2.5]
	at org.postgresql.core.v3.QueryExecutorImpl.processResults(QueryExecutorImpl.java:2183) ~[postgresql-42.2.5.jar!/:42.2.5]
	at org.postgresql.core.v3.QueryExecutorImpl.execute(QueryExecutorImpl.java:308) ~[postgresql-42.2.5.jar!/:42.2.5]
	at org.postgresql.jdbc.PgStatement.executeInternal(PgStatement.java:441) ~[postgresql-42.2.5.jar!/:42.2.5]
	at org.postgresql.jdbc.PgStatement.execute(PgStatement.java:365) ~[postgresql-42.2.5.jar!/:42.2.5]
	at org.postgresql.jdbc.PgStatement.executeWithFlags(PgStatement.java:307) ~[postgresql-42.2.5.jar!/:42.2.5]
	at org.postgresql.jdbc.PgStatement.executeCachedSql(PgStatement.java:293) ~[postgresql-42.2.5.jar!/:42.2.5]
	at org.postgresql.jdbc.PgStatement.executeWithFlags(PgStatement.java:270) ~[postgresql-42.2.5.jar!/:42.2.5]
	at org.postgresql.jdbc.PgConnection.execSQLUpdate(PgConnection.java:440) ~[postgresql-42.2.5.jar!/:42.2.5]
	at org.postgresql.jdbc.PgConnection.releaseSavepoint(PgConnection.java:1666) ~[postgresql-42.2.5.jar!/:42.2.5]
	at com.zaxxer.hikari.pool.HikariProxyConnection.releaseSavepoint(HikariProxyConnection.java) ~[HikariCP-3.2.0.jar!/:na]
	at io.crdb.demo.store.runner.StartupRunner.lambda$createAuthorization$2(StartupRunner.java:263) ~[classes!/:2019.1-BETA]
	at io.micrometer.core.instrument.AbstractTimer.record(AbstractTimer.java:149) ~[micrometer-core-1.1.3.jar!/:1.1.3]
	at io.crdb.demo.store.runner.StartupRunner.createAuthorization(StartupRunner.java:206) ~[classes!/:2019.1-BETA]
	at io.crdb.demo.store.runner.StartupRunner.lambda$runTests$0(StartupRunner.java:131) ~[classes!/:2019.1-BETA]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149) ~[na:1.8.0_191]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624) ~[na:1.8.0_191]
	at java.lang.Thread.run(Thread.java:748) ~[na:1.8.0_191]
