# Store Demo - Docker

## Services
* `node-a` - CockroachDB node in region `A`
* `node-b` - CockroachDB node in region `B`
* `node-c` - CockroachDB node in region `C`
* `node-d` - CockroachDB node in region `D`
* `node-e` - CockroachDB node in region `E`
* `node-f` - CockroachDB node in region `F`
* `lb` - HAProxy acting as load balancer
* `prometheus` - Prometheus server
* `grafana` - Grafana UI

## Getting started
1) Create a file called `.env` in the root of the `docker` folder with the following content...
    ```
    ORG=<MY LICENSE ORG>
    KEY=<MY LICENSE KEY>
    ```
    Replace `<MY LICENSE ORG>` with the organization associated with your enterprise license and `<MY LICENSE KEY>` with your enterprise license key.
2) Run `./up.sh` or `docker-compose up -d` to start the Docker services   
3) Visit the CockroachDB UI @ http://localhost:8080
4) Visit the HAProxy UI @ http://localhost:8081
5) Visit the Grafana UI @ http://localhost:3000.  Default username and password are `admin`/`admin`.
6) Visit the Prometheus UI @ http://localhost:9090
7) Have fun!

You can run `./down.sh` to stop the Docker services and `./prune.sh` to do a Docker system prune when you are finished.

## Helpful Commands

### Show Ranges
Ranges and data distribution can be viewed in the UI here (http://localhost:8080/#/data-distribution) or via the following commands:
```bash
docker-compose exec east-1 /cockroach/cockroach sql --insecure --database=store_demo --execute="SELECT * FROM [SHOW EXPERIMENTAL_RANGES FROM TABLE auth] WHERE \"start_key\" IS NOT NULL AND \"start_key\" NOT LIKE '%Prefix%';"
docker-compose exec east-1 /cockroach/cockroach sql --insecure --database=store_demo --execute="SELECT * FROM [SHOW EXPERIMENTAL_RANGES FROM TABLE acct] WHERE \"start_key\" IS NOT NULL AND \"start_key\" NOT LIKE '%Prefix%';"
```

### Open Interactive Shells
```bash
docker exec -ti node-a /bin/bash
docker exec -ti node-b /bin/bash
docker exec -ti node-c /bin/bash
docker exec -ti node-d /bin/bash
docker exec -ti node-e /bin/bash
docker exec -ti node-f /bin/bash
```