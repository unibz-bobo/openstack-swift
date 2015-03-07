#!/bin/bash

# Description
#
# Read filename

# specific settings for proxy
PROXY_HOSTS="10.10.242.97 10.10.242.12"
# NOTE this is the proxy that is first configured
MASTER_PROXY="10.10.242.97"
LOAD_BALANCER="10.10.242.55"

# specific settings for storage
ACCOUNT_HOSTS="10.10.242.98 10.10.242.52"
CONTAINER_HOSTS="10.10.242.99 10.10.242.54"
OBJECT_HOSTS="10.10.242.56 10.10.242.6"

# does the script have to create separate zones ?
# at the moment, a zone is a single group account-container-object
CREATE_ZONES=0

# Replication count
REPLICATION=1

# Partition power (2^n)
PARTITIONS=0
