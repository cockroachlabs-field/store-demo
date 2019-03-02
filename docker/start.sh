#!/bin/bash

docker-compose up -d

echo "waiting for cluster to come up..."
sleep 20

echo "configuring cluster and database..."
docker-compose exec east-1 /cockroach/cockroach sql --insecure --execute="SET CLUSTER SETTING cluster.organization = 'tv';"
docker-compose exec east-1 /cockroach/cockroach sql --insecure --execute="SET CLUSTER SETTING enterprise.license = 'crl-0-EPGo8OMFGAIiAnR2';"
docker-compose exec east-1 /cockroach/cockroach sql --insecure --execute="SET CLUSTER SETTING server.remote_debugging.mode = \"any\";"
docker-compose exec east-1 /cockroach/cockroach sql --insecure --execute="CREATE DATABASE store_demo;"
docker-compose exec east-1 /cockroach/cockroach sql --insecure --execute="INSERT into system.locations VALUES ('region', 'east', 33.191333, -80.003999);"
docker-compose exec east-1 /cockroach/cockroach sql --insecure --execute="INSERT into system.locations VALUES ('region', 'central', 29.4167, -98.5);"
docker-compose exec east-1 /cockroach/cockroach sql --insecure --execute="INSERT into system.locations VALUES ('region', 'west', 34.052235, -118.243683);"