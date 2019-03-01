#!/bin/bash

sudo mkfs.ext4 -F /dev/nvme0n1

sudo mkdir -p /mnt/disks/cockroach

sudo mount -o discard,defaults,nobarrier /dev/nvme0n1 /mnt/disks/cockroach

sudo chmod a+w /mnt/disks/cockroach