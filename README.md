# store-demo
General purpose demo that highlights multi-region workload with locality and failure

took `8847` seconds or roughly `2.5` hours to generate `450,000,000` account records with roughly `5,000,000` activations


http://localhost:8082/actuator/metrics/runner.available_balance
http://localhost:8082/actuator/metrics/runner.create_auth
http://localhost:8082/actuator/metrics/runner.update_auth



terraform init -upgrade
terraform plan -var="gcp_project_name=cockroach-tv" -var="gcp_user=timveil" -refresh=true
terraform plan -var="gcp_project_name=cockroach-tv" -var="gcp_user=timveil" -refresh=true -target azurerm_resource_group.sd_resource_group -out run.plan

terraform apply -var="gcp_project_name=cockroach-tv" -var="gcp_user=timveil" -auto-approve -refresh=true
terraform apply -var="gcp_project_name=cockroach-tv" -var="gcp_user=timveil" -var="region_node_count=1" -auto-approve -refresh=true

terraform refresh -var="gcp_project_name=cockroach-tv" -var="gcp_user=timveil"

terraform destroy -var="gcp_project_name=cockroach-tv" -var="gcp_user=timveil" -auto-approve
terraform destroy -var="gcp_project_name=cockroach-tv" -var="gcp_user=timveil" -auto-approve -target azurerm_resource_group.sd_resource_group


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

```bash
cockroach workload init tpcc --warehouses=400 --drop
```

```bash
cockroach workload run tpcc --ramp=5m --warehouses=400 --active-warehouses=400 --duration=15m --split --scatter
```

``` 
before 
azureuser@sd-azure-central-0:~$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
fd0      2:0    1    4K  0 disk
sda      8:0    0  100G  0 disk
└─sda1   8:1    0   30G  0 part /
sdb      8:16   0  280G  0 disk
└─sdb1   8:17   0  280G  0 part /mnt/resource
sr0     11:0    1  628K  0 rom
```



sudo mkfs.ext4 -F /dev/sdc

sudo mkdir -p /mnt/disks/cockroach

sudo mount -o discard,defaults,nobarrier /dev/sdc /mnt/disks/cockroach

sudo chmod a+w /mnt/disks/cockroach