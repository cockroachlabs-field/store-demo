#!/bin/bash

CRDB_VERSION=$1

echo "installing CRDB version ${CRDB_VERSION}"

wget -qO- https://binaries.cockroachdb.com/cockroach-${CRDB_VERSION}.linux-amd64.tgz | tar xvz
sudo cp -fv cockroach-${CRDB_VERSION}.linux-amd64/cockroach /usr/local/bin