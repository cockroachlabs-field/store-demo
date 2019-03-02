ALTER PARTITION east OF TABLE ACCT CONFIGURE ZONE USING constraints='[+region=east]';
ALTER PARTITION central OF TABLE ACCT CONFIGURE ZONE USING constraints='[+region=central]';
ALTER PARTITION west OF TABLE ACCT CONFIGURE ZONE USING constraints='[+region=west]';
ALTER PARTITION east OF TABLE AUTH CONFIGURE ZONE USING constraints='[+region=east]';
ALTER PARTITION central OF TABLE AUTH CONFIGURE ZONE USING constraints='[+region=central]';
ALTER PARTITION west OF TABLE AUTH CONFIGURE ZONE USING constraints='[+region=west]';