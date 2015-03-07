
#!/bin/bash

# Description
#
# THIS CONFIGURATION HAS BEEN AUTOMATICALLY GENERATED!!
#   DO NOT HAND-EDIT!!
# Total nodes: 26 (4 in use)
# 1 Proxies ; 1 Accounts ; 1 Containers ; 1 Object
# Single zone, single region

# specific settings for proxy
PROXY_HOSTS="10.10.242.97"
# NOTE this is the proxy that is first configured
MASTER_PROXY="10.10.242.97"
LOAD_BALANCER="10.10.242.55"

# specific settings for storage
ACCOUNT_HOSTS="10.10.242.98"
CONTAINER_HOSTS="10.10.242.99"
OBJECT_HOSTS="10.10.242.56"

# does the script have to create separate zones ?
# at the moment, a zone is a single group account-container-object
CREATE_ZONES=1

# Replication count
REPLICATION=1

# Partition power (2^n)
PARTITIONS=7
