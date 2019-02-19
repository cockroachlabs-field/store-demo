#!/bin/bash

docker-compose up -d

echo "waiting for cluster to come up..."
sleep 20

echo "configuring cluster and database..."
docker-compose exec crdb-1 /cockroach/cockroach sql --insecure --execute="SET CLUSTER SETTING cluster.organization = 'tv';"
docker-compose exec crdb-1 /cockroach/cockroach sql --insecure --execute="SET CLUSTER SETTING enterprise.license = 'crl-0-EPGo8OMFGAIiAnR2';"
docker-compose exec crdb-1 /cockroach/cockroach sql --insecure --execute="SET CLUSTER SETTING server.remote_debugging.mode = \"any\";"
docker-compose exec crdb-1 /cockroach/cockroach sql --insecure --execute="CREATE DATABASE store_demo;"