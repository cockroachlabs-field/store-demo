#!/bin/bash

DRIVE_PATH=$1

if [[ -z "$DRIVE_PATH" ]]; then
    echo "Must provide DRIVE_PATH as the first parameter." 1>&2
    exit 1
fi

sudo mkfs.ext4 -F $DRIVE_PATH

sudo mkdir -p /mnt/disks/cockroach

sudo mount -o discard,defaults,nobarrier $DRIVE_PATH /mnt/disks/cockroach

sudo chmod a+w /mnt/disks/cockroach