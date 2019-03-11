ALTER PARTITION east OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='[+region=east]', lease_preferences='[[+region=east]]';
ALTER PARTITION central OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='[+region=central]', lease_preferences='[[+region=central]]';
ALTER PARTITION west OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='[+region=west]', lease_preferences='[[+region=west]]';
ALTER PARTITION east OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='[+region=east]', lease_preferences='[[+region=east]]';
ALTER PARTITION central OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='[+region=central]', lease_preferences='[[+region=central]]';
ALTER PARTITION west OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='[+region=west]', lease_preferences='[[+region=west]]';