# Store Demo - Docker

## Services
* `ATL1` - CockroachDB node in region `ATL1`
* `ATL2` - CockroachDB node in region `ATL2`
* `TX1` - CockroachDB node in region `TX1`
* `TX2` - CockroachDB node in region `TX2`
* `lb` - HAProxy acting as load balancer
* `prometheus` - Prometheus server
* `grafana` - Grafana UI

## Getting started
1) Because operation order is important, execute `./start.sh <MY LICENSE ORG> <MY LICENSE KEY>` instead of `docker-compose up`.  Replace `<MY LICENSE ORG>` with the organization associated with your enterprise license and `<MY LICENSE KEY>` with your enterprise license key.
2) Visit the CockroachDB UI @ http://localhost:8080
3) Visit the HAProxy UI @ http://localhost:8081
3) Visit the Grafana UI @ http://localhost:3000.  Default username and password are `admin`/`admin`.
3) Visit the Prometheus UI @ http://localhost:9090
3) Have fun!

## Helpful Commands

### Show Ranges
Ranges and data distribution can be viewed in the UI here (http://localhost:8080/#/data-distribution) or via the following commands:
```bash
docker-compose exec ATL1 /cockroach/cockroach sql --insecure --database=store_demo --execute="SELECT * FROM [SHOW EXPERIMENTAL_RANGES FROM TABLE auth] WHERE \"start_key\" IS NOT NULL AND \"start_key\" NOT LIKE '%Prefix%';"
docker-compose exec ATL1 /cockroach/cockroach sql --insecure --database=store_demo --execute="SELECT * FROM [SHOW EXPERIMENTAL_RANGES FROM TABLE acct] WHERE \"start_key\" IS NOT NULL AND \"start_key\" NOT LIKE '%Prefix%';"
```

### Open Interactive Shells
```bash
docker exec -ti ATL1 /bin/bash
docker exec -ti ATL2 /bin/bash
docker exec -ti TX1 /bin/bash
docker exec -ti TX2 /bin/bash
```