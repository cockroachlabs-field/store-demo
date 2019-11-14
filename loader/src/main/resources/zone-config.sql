ALTER PARTITION ATL1 OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=ATL1": 1, "+region=ATL2": 1, "+region=TX1": 1}', lease_preferences='[[+region=ATL1],[+region=ATL2],[+region=TX1]]';
ALTER PARTITION ATL2 OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=ATL2": 1, "+region=ATL1": 1, "+region=TX2": 1}', lease_preferences='[[+region=ATL2],[+region=ATL1],[+region=TX2]]';
ALTER PARTITION TX1 OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=TX1": 1, "+region=TX2": 1, "+region=ATL1": 1}', lease_preferences='[[+region=TX1],[+region=TX2],[+region=ATL1]]';
ALTER PARTITION TX2 OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=TX2": 1, "+region=TX1": 1, "+region=ATL2": 1}', lease_preferences='[[+region=TX2],[+region=TX1],[+region=ATL2]]';

ALTER PARTITION ATL1 OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=ATL1": 1, "+region=ATL2": 1, "+region=TX1": 1}', lease_preferences='[[+region=ATL1],[+region=ATL2],[+region=TX1]]';
ALTER PARTITION ATL2 OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=ATL2": 1, "+region=ATL1": 1, "+region=TX2": 1}', lease_preferences='[[+region=ATL2],[+region=ATL1],[+region=TX2]]';
ALTER PARTITION TX1 OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=TX1": 1, "+region=TX2": 1, "+region=ATL1": 1}', lease_preferences='[[+region=TX1],[+region=TX2],[+region=ATL1]]';
ALTER PARTITION TX2 OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=TX2": 1, "+region=TX1": 1, "+region=ATL2": 1}', lease_preferences='[[+region=TX2],[+region=TX1],[+region=ATL2]]';
