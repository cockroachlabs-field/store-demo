#!/bin/bash

CRDB_ORG=$1
CRDB_LICENSE_KEY=$2

if [[ -z "$CRDB_ORG" ]]; then
    echo "Must provide CRDB_ORG as the first parameter. Example './start.sh MY_ORG MY_KEY'." 1>&2
    exit 1
fi

if [[ -z "$CRDB_LICENSE_KEY" ]]; then
    echo "Must provide CRDB_LICENSE_KEY as the second parameter. Example './start.sh MY_ORG MY_KEY'." 1>&2
    exit 1
fi

docker-compose up -d

echo "waiting for cluster to come up..."
sleep 20

echo "configuring cluster and database with cluster.organization = ${CRDB_ORG} and enterprise.license = ${CRDB_LICENSE_KEY}"
docker-compose exec node-a /cockroach/cockroach sql --insecure --execute="SET CLUSTER SETTING cluster.organization = '${CRDB_ORG}';"
docker-compose exec node-a /cockroach/cockroach sql --insecure --execute="SET CLUSTER SETTING enterprise.license = '${CRDB_LICENSE_KEY}';"
docker-compose exec node-a /cockroach/cockroach sql --insecure --execute="SET CLUSTER SETTING server.remote_debugging.mode = \"any\";"
docker-compose exec node-a /cockroach/cockroach sql --insecure --execute="CREATE DATABASE IF NOT EXISTS store_demo;"