ALTER PARTITION A OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=A": 1, "+region=B": 1, "+region=C": 1}', lease_preferences='[[+region=A],[+region=B],[+region=C]]';
ALTER PARTITION B OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=B": 1, "+region=A": 1, "+region=D": 1}', lease_preferences='[[+region=B],[+region=A],[+region=D]]';
ALTER PARTITION C OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=C": 1, "+region=D": 1, "+region=A": 1}', lease_preferences='[[+region=C],[+region=D],[+region=A]]';
ALTER PARTITION D OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=D": 1, "+region=C": 1, "+region=B": 1}', lease_preferences='[[+region=D],[+region=C],[+region=B]]';
ALTER PARTITION E OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=E": 1, "+region=F": 1, "+region=C": 1}', lease_preferences='[[+region=E],[+region=F],[+region=C]]';
ALTER PARTITION F OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=F": 1, "+region=E": 1, "+region=D": 1}', lease_preferences='[[+region=F],[+region=E],[+region=D]]';

ALTER PARTITION A OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=A": 1, "+region=B": 1, "+region=C": 1}', lease_preferences='[[+region=A],[+region=B],[+region=C]]';
ALTER PARTITION B OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=B": 1, "+region=A": 1, "+region=D": 1}', lease_preferences='[[+region=B],[+region=A],[+region=D]]';
ALTER PARTITION C OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=C": 1, "+region=D": 1, "+region=A": 1}', lease_preferences='[[+region=C],[+region=D],[+region=A]]';
ALTER PARTITION D OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=D": 1, "+region=C": 1, "+region=B": 1}', lease_preferences='[[+region=D],[+region=C],[+region=B]]';
ALTER PARTITION E OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=E": 1, "+region=F": 1, "+region=C": 1}', lease_preferences='[[+region=E],[+region=F],[+region=C]]';
ALTER PARTITION F OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=F": 1, "+region=E": 1, "+region=D": 1}', lease_preferences='[[+region=F],[+region=E],[+region=D]]';
