CREATE TABLE AUTH (
  ACCT_NBR         STRING(25)     NOT NULL,
  REQUEST_ID       UUID           NOT NULL,
  AUTH_ID          STRING(64)     NOT NULL,
  AUTH_AMT         DECIMAL(18, 4) NOT NULL,
  AUTH_STAT_CD     DECIMAL(2, 0)  NOT NULL,
  CRT_TS           TIMESTAMP      NOT NULL,
  LAST_UPD_TS      TIMESTAMP      NOT NULL,
  LAST_UPD_USER_ID STRING(8)      NOT NULL,
  STATE            STRING(2)      NOT NULL,
  PRIMARY KEY (STATE ASC, ACCT_NBR ASC, REQUEST_ID ASC))
  PARTITION BY LIST (STATE) (
    PARTITION gcp_east VALUES IN ('SC'),
    PARTITION azure_east VALUES IN ('VA'),
    PARTITION gcp_central VALUES IN ('IA'),
    PARTITION gcp_west VALUES IN ('CA'),
    PARTITION azure_west VALUES IN ('WA'));