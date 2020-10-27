#!/bin/bash

wget -qO- https://binaries.cockroachdb.com/cockroach-latest.linux-amd64.tgz | tar xz --strip-components=1
sudo cp -fv cockroach /usr/local/bin