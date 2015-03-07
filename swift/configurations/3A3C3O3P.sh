
#!/bin/bash

# Description
#
# THIS CONFIGURATION HAS BEEN AUTOMATICALLY GENERATED!!
#   DO NOT HAND-EDIT!!
# Total nodes: 26 (12 in use)
# 3 Proxies ; 3 Accounts ; 3 Containers ; 3 Object
# Single zone, single region

# specific settings for proxy
PROXY_HOSTS="10.10.242.97 10.10.242.12 10.10.242.10"
# NOTE this is the proxy that is first configured
MASTER_PROXY="10.10.242.97"
LOAD_BALANCER="10.10.242.55"

# specific settings for storage
ACCOUNT_HOSTS="10.10.242.98 10.10.242.52 10.10.242.8"
CONTAINER_HOSTS="10.10.242.99 10.10.242.54 10.10.242.45"
OBJECT_HOSTS="10.10.242.56 10.10.242.6 10.10.242.46"

# does the script have to create separate zones ?
# at the moment, a zone is a single group account-container-object
CREATE_ZONES=1

# Replication count
REPLICATION=3

# Partition power (2^n)
PARTITIONS=7
