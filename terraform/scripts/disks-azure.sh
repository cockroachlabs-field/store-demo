#!/bin/bash

sudo mkfs.ext4 -F /dev/sdc

sudo mkdir -p /mnt/disks/cockroach

sudo mount -o discard,defaults,nobarrier /dev/sdc /mnt/disks/cockroach

sudo chmod a+w /mnt/disks/cockroach