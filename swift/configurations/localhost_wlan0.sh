#!/bin/bash

# Description
#
# This is the very basic setup. Deployment on a single machine.
# The machine is the localhost but might be a remote host too.
# Single zone, single region

HOST_IP=`LANG=C ifconfig wlan0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`

# specific settings for proxy
PROXY_HOSTS="$HOST_IP"
# NOTE this is the proxy that is first configured
MASTER_PROXY="$HOST_IP"
LOAD_BALANCER="$HOST_IP"

# specific settings for storage
ACCOUNT_HOSTS="$HOST_IP"
CONTAINER_HOSTS="$HOST_IP"
OBJECT_HOSTS="$HOST_IP"

# does the script have to create separate zones ?
# at the moment, a zone is a single group account-container-object
CREATE_ZONES=1

# Replication count
REPLICATION=3

# Partition power (2^n)
PARTITIONS=7

# OpenStack Swift Release (NOTE: this is the git tag name)
RELEASE="2.5.0"

# Choice of the filesystem. Check the main script for the possible
# valid values, which are currently at least XFS and F2FS (literally)
FILESYSTEM="XFS"

# Name here the path of the (S/H)DD if you are using one
SSD_PARTITION_PATH=""
