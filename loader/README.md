# Store Demo - Loader

--create --crdb.server=PRIVATE_IP_OF_IN-REGION_NODE --crdb.accts=PORTION_OF_TOTAL --crdb.auths=PORTION_OF_TOTAL --crdb.locality=STATE


scp loader-2019.1-BETA.jar timveil@35.196.10.62:~/


java -jar loader-2019.1-BETA.jar --create --crdb.server=10.142.0.3 --crdb.port=26257 --crdb.accts=150000000 --crdb.auths=300000 --crdb.locality=VA

java -jar loader-2019.1-BETA.jar --load --crdb.server=10.142.0.3 --crdb.port=26257