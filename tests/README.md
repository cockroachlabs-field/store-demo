# Tests

## Locality Test: 3/10/19
3 regions, 3 nodes each

### Summary
region | completed | update retries | insert retries
------------ | ------------- | ------------- | -------------
east | 3,742,681 | 1 | 3
west | 3,652,971 | 65 | 44
central | 2,231,110 | 30 | 10
------------ | ------------- | ------------- | -------------
__total__ | __9,626,762__ | __96__ | __47__

### GCP east
```
Test Summary
    Test ID: 7hNqTkUz
    Duration: 30
    State: SC
    Region: east
    # Threads: 256
    # Transactions Completed: 3742681
    # Unique Accounts Used: 3742681
    # Accounts Updated: 3742681
    # Update Retries: 1
    # Insert Retries: 3
    # Balances Not Found: 0
    Total Time in MS: 1800230
```

### GCP west
```
Test Summary
    Test ID: Qe35rwUg
    Duration: 30
    State: CA
    Region: west
    # Threads: 256
    # Transactions Completed: 3652971
    # Unique Accounts Used: 3652971
    # Accounts Updated: 3652971
    # Update Retries: 65
    # Insert Retries: 44
    # Balances Not Found: 0
    Total Time in MS: 1800156
```

### Azure central
```
Test Summary
    Test ID: 8FDeHMWK
    Duration: 30
    State: TX
    Region: central
    # Threads: 256
    # Transactions Completed: 2231110
    # Unique Accounts Used: 2231110
    # Accounts Updated: 2231110
    # Update Retries: 30
    # Insert Retries: 10
    # Balances Not Found: 0
    Total Time in MS: 1800229
```
### Screenshots
![Screenshot](Fullscreen_3_10_19__6_04_PM.png)

## Locality Test: 3/10/19
3 regions, 3 nodes each; removed concurrent set for unique account number check


### Summary
region | completed | update retries | insert retries
------------ | ------------- | ------------- | -------------
east | 3,788,632 | 0 | 0
west | 4,097,895 | 2 | 9
central | 2,128,919 | 8 | 2
------------ | ------------- | ------------- | -------------
__total__ | __10,015,446__ | __10__ | __11__

### GCP east
```
Test Summary
    Test ID: OS80nj5b
    Duration: 30
    State: SC
    Region: east
    # Threads: 256
    # Transactions Completed: 3788632
    # Accounts Updated: 3788632
    # Update Retries: 0
    # Insert Retries: 0
    # Balances Not Found: 0
    Total Time in MS: 1800228

```

### GCP west
```
Test Summary
    Test ID: 2W60cwtq
    Duration: 30
    State: CA
    Region: west
    # Threads: 256
    # Transactions Completed: 4097895
    # Accounts Updated: 4097895
    # Update Retries: 2
    # Insert Retries: 9
    # Balances Not Found: 0
    Total Time in MS: 1800175

```

### Azure central
```
Test Summary
    Test ID: bEZbmVm4
    Duration: 30
    State: TX
    Region: central
    # Threads: 256
    # Transactions Completed: 2128919
    # Accounts Updated: 2128919
    # Update Retries: 8
    # Insert Retries: 2
    # Balances Not Found: 0
    Total Time in MS: 1800343

```

### Screenshots
![Screenshot](Fullscreen_3_10_19__7_12_PM.png)