
#!/bin/bash

# Description
#
# THIS CONFIGURATION HAS BEEN AUTOMATICALLY GENERATED!!
#   DO NOT HAND-EDIT!!
# Total nodes: 26 (8 in use)
# 2 Proxies ; 2 Accounts ; 2 Containers ; 2 Object
# Single zone, single region

# specific settings for proxy
PROXY_HOSTS="10.10.241.200"
# NOTE this is the proxy that is first configured
MASTER_PROXY="10.10.241.200"
LOAD_BALANCER="10.10.241.200"

# specific settings for storage
ACCOUNT_HOSTS="10.10.241.201 10.10.241.202"
CONTAINER_HOSTS="10.10.241.203 10.10.241.204"
OBJECT_HOSTS="10.10.241.205 10.10.241.206"

# does the script have to create separate zones ?
# at the moment, a zone is a single group account-container-object
CREATE_ZONES=1

# Replication count
REPLICATION=2

# Partition power (2^n)
PARTITIONS=7

# OpenStack Swift Release (NOTE: this is the git tag name)
RELEASE="2.5.0"

# Choice of the filesystem. Check the main script for the possible
# valid values, which are currently at least XFS and F2FS (literally)
FILESYSTEM="XFS"
