ALTER PARTITION gcp_east OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-east": 1, "+region=azure-east": 1}', lease_preferences='[[+region=gcp-east]]';
ALTER PARTITION azure_east OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-east": 1, "+region=azure-east": 1}', lease_preferences='[[+region=azure-east]]';
ALTER PARTITION gcp_central OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-central": 1, "+region=azure-east": 1}', lease_preferences='[[+region=gcp-central]]';
ALTER PARTITION gcp_west OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-west": 1, "+region=azure-west": 1}', lease_preferences='[[+region=gcp-west]]';
ALTER PARTITION azure_west OF TABLE ACCT CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-west": 1, "+region=azure-west": 1}', lease_preferences='[[+region=azure-west]]';

ALTER PARTITION gcp_east OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-east": 1, "+region=azure-east": 1}', lease_preferences='[[+region=gcp-east]]';
ALTER PARTITION azure_east OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-east": 1, "+region=azure-east": 1}', lease_preferences='[[+region=azure-east]]';
ALTER PARTITION gcp_central OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-central": 1, "+region=azure-east": 1}', lease_preferences='[[+region=gcp-central]]';
ALTER PARTITION gcp_west OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-west": 1, "+region=azure-west": 1}', lease_preferences='[[+region=gcp-west]]';
ALTER PARTITION azure_west OF TABLE AUTH CONFIGURE ZONE USING gc.ttlseconds=600, constraints='{"+region=gcp-west": 1, "+region=azure-west": 1}', lease_preferences='[[+region=azure-west]]';