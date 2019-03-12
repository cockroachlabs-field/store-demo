ALTER PARTITION A OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=A": 1, "+region=B": 1, "+region=C": 1}', lease_preferences='[[+region=A]]';
ALTER PARTITION B OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=A": 1, "+region=B": 1, "+region=D": 1}', lease_preferences='[[+region=B]]';
ALTER PARTITION C OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=C": 1, "+region=D": 1, "+region=A": 1}', lease_preferences='[[+region=C]]';
ALTER PARTITION D OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=C": 1, "+region=D": 1, "+region=B": 1}', lease_preferences='[[+region=D]]';
ALTER PARTITION D OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=E": 1, "+region=F": 1, "+region=C": 1}', lease_preferences='[[+region=E]]';
ALTER PARTITION F OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=E": 1, "+region=F": 1, "+region=D": 1}', lease_preferences='[[+region=F]]';
