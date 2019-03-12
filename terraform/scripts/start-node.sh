#!/bin/bash

CRDB_CACHE=$1
CRDB_SQL_MEMORY=$2
CRDB_REGION=$3
CRDB_PRIVATE_IP=$4
CRDB_PUBLIC_IP=$5
CRDB_JOIN=$6

if [[ -z "$CRDB_CACHE" ]]; then
    echo "Must provide CRDB_CACHE as the first parameter." 1>&2
    exit 1
fi

if [[ -z "$CRDB_SQL_MEMORY" ]]; then
    echo "Must provide CRDB_SQL_MEMORY as the second parameter." 1>&2
    exit 1
fi

if [[ -z "$CRDB_REGION" ]]; then
    echo "Must provide CRDB_REGION as the third parameter." 1>&2
    exit 1
fi

if [[ -z "$CRDB_PRIVATE_IP" ]]; then
    echo "Must provide CRDB_PRIVATE_IP as the forth parameter." 1>&2
    exit 1
fi

if [[ -z "$CRDB_PUBLIC_IP" ]]; then
    echo "Must provide CRDB_PUBLIC_IP as the fifth parameter." 1>&2
    exit 1
fi

if [[ -z "$CRDB_JOIN" ]]; then
    echo "Must provide CRDB_JOIN as the sixth parameter." 1>&2
    exit 1
fi

while [[ ! -f /tmp/instance-ready ]]; do echo 'waiting for node to be ready...'; sleep 1; done

cockroach start \
    --background \
    --insecure \
    --logtostderr=NONE \
    --log-dir=/mnt/disks/cockroach \
    --store=/mnt/disks/cockroach \
    --cache=${CRDB_CACHE} \
    --max-sql-memory=${CRDB_SQL_MEMORY} \
    --locality=region=${CRDB_REGION} \
    --locality-advertise-addr=region=${CRDB_REGION}@${CRDB_PRIVATE_IP} \
    --advertise-addr=${CRDB_PUBLIC_IP} \
    --join=${CRDB_JOIN}