
#!/bin/bash

# Description
#
# THIS CONFIGURATION HAS BEEN AUTOMATICALLY GENERATED!!
#   DO NOT HAND-EDIT!!
# Total nodes: 26 (8 in use)
# 2 Proxies ; 2 Accounts ; 2 Containers ; 2 Object
# Single zone, single region

# specific settings for proxy
PROXY_HOSTS="10.10.241.211 10.10.241.212 10.10.241.213"
# NOTE this is the proxy that is first configured
MASTER_PROXY="10.10.241.211"
LOAD_BALANCER="127.0.0.1"

# specific settings for storage
ACCOUNT_HOSTS="10.10.241.211 10.10.241.212 10.10.241.213"
CONTAINER_HOSTS="10.10.241.211 10.10.241.212 10.10.241.213"
OBJECT_HOSTS="10.10.241.214 10.10.241.215 10.10.241.216 10.10.241.217"

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
SSD_PARTITION_PATH="/dev/sda1"
