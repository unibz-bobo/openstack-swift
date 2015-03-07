#!/bin/bash

# Description
#
# This is an "unbalanced" topology were we have several object nodes while
# having a single account node and a single container node
# We have 3 proxy servers
# Single zone, single region

# specific settings for proxy
PROXY_HOSTS="10.10.242.97 10.10.242.98 10.10.242.99 10.10.242.56 10.10.242.12 10.10.242.52 10.10.242.54"
# NOTE this is the proxy that is first configured
MASTER_PROXY="10.10.242.99"
LOAD_BALANCER="10.10.242.55"

# specific settings for storage
ACCOUNT_HOSTS="10.10.242.6"
CONTAINER_HOSTS="10.10.242.10"
OBJECT_HOSTS="10.10.242.8 10.10.242.45 10.10.242.46 10.10.242.47 10.10.242.48 10.10.242.49 10.10.242.50 10.10.242.53 10.10.242.7 10.10.242.9 10.10.242.51 10.10.242.11 10.10.242.57 10.10.242.59 10.10.242.60 10.10.242.61 10.10.242.62"

# does the script have to create separate zones ?
# at the moment, a zone is a single group account-container-object
CREATE_ZONES=0

# Replication count
REPLICATION=3

# Partition power (2^n)
PARTITIONS=7
