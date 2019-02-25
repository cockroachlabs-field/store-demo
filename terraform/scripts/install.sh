#!/bin/bash

cat > /etc/ntp.conf << EOL
server metadata.google.internal iburst
EOL

sudo service ntp reload

wget -qO- https://binaries.cockroachdb.com/cockroach-v2.1.5.linux-amd64.tgz | tar  xvz

sudo cp -i cockroach-v2.1.5.linux-amd64/cockroach /usr/local/bin