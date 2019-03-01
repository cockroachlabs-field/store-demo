# store-demo
General purpose demo that highlights multi-region workload with locality and failure

took `8847` seconds or roughly `2.5` hours to generate `450,000,000` account records with roughly `5,000,000` activations


http://localhost:8082/actuator/metrics/runner.available_balance
http://localhost:8082/actuator/metrics/runner.create_auth
http://localhost:8082/actuator/metrics/runner.update_auth



terraform init -upgrade
terraform refresh -var-file="store-demo.tfvars"
terraform plan -var-file="store-demo.tfvars"

terraform apply -var-file="store-demo.tfvars" -auto-approve


terraform destroy -var-file="store-demo.tfvars" -auto-approve


## Run 1
Azure `Standard_D12_v2`

```bash
cockroach workload init tpcc
```

```bash
cockroach workload run tpcc --duration=10m
```
```
_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  600.0s        0             12            0.0   1097.5    771.8   1677.7   2818.6   2818.6  delivery
  600.0s        0            122            0.2   1261.0   1073.7   2281.7   5637.1   6442.5  newOrder
  600.0s        0             12            0.0    131.7     10.0    453.0    939.5    939.5  orderStatus
  600.0s        0            121            0.2    581.4    352.3   1811.9   3087.0   3221.2  payment
  600.0s        0             15            0.0    519.8    260.0   1610.6   2013.3   2013.3  stockLevel

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__result
  600.0s        0            282            0.5    875.0    771.8   2080.4   4563.4   6442.5
Audit check 9.2.1.7: SKIP: not enough delivery transactions to be statistically significant
Audit check 9.2.2.5.1: SKIP: not enough orders to be statistically significant
Audit check 9.2.2.5.2: SKIP: not enough orders to be statistically significant
Audit check 9.2.2.5.3: SKIP: not enough orders to be statistically significant
Audit check 9.2.2.5.4: SKIP: not enough payments to be statistically significant
Audit check 9.2.2.5.5: SKIP: not enough payments to be statistically significant
Audit check 9.2.2.5.6: SKIP: not enough order status transactions to be statistically significant

_elapsed_______tpmC____efc__avg(ms)__p50(ms)__p90(ms)__p95(ms)__p99(ms)_pMax(ms)
  600.0s       12.2  94.9%   1261.0   1073.7   1744.8   2281.7   5637.1   6442.5
```

## Run 2
This run is after significant changes, increased instance types, fixed disks, synced clocks, implemented locality, etc.

```bash
cockroach workload init tpcc
```

```bash
cockroach workload run tpcc --duration=10m
```
```
_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  600.0s        0             12            0.0   1180.0    872.4   2147.5   2281.7   2281.7  delivery
  600.0s        0            123            0.2    987.7    838.9   1610.6   5905.6   6710.9  newOrder
  600.0s        0             10            0.0    105.4     50.3    385.9    385.9    385.9  orderStatus
  600.0s        0            136            0.2    487.9    335.5   1275.1   2415.9   2684.4  payment
  600.0s        0             14            0.0    269.9    243.3    469.8    536.9    536.9  stockLevel

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__result
  600.0s        0            295            0.5    701.1    604.0   1476.4   3892.3   6710.9
Audit check 9.2.1.7: SKIP: not enough delivery transactions to be statistically significant
Audit check 9.2.2.5.1: SKIP: not enough orders to be statistically significant
Audit check 9.2.2.5.2: SKIP: not enough orders to be statistically significant
Audit check 9.2.2.5.3: SKIP: not enough orders to be statistically significant
Audit check 9.2.2.5.4: SKIP: not enough payments to be statistically significant
Audit check 9.2.2.5.5: SKIP: not enough payments to be statistically significant
Audit check 9.2.2.5.6: SKIP: not enough order status transactions to be statistically significant

_elapsed_______tpmC____efc__avg(ms)__p50(ms)__p90(ms)__p95(ms)__p99(ms)_pMax(ms)
  600.0s       12.3  95.6%    987.7    838.9   1208.0   1610.6   5905.6   6710.9

```


## Optional

```bash
cockroach workload init tpcc --warehouses=400 --drop
```

```bash
cockroach workload run tpcc --ramp=5m --warehouses=400 --active-warehouses=400 --duration=15m --split --scatter
```

