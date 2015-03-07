#!/bin/bash

# Description
#
# This is the very basic setup. Deployment on a single machine.
# The machine is the localhost but might be a remote host too.
# Single zone, single region

# specific settings for proxy
PROXY_HOSTS="10.10.242.6"
# NOTE this is the proxy that is first configured
MASTER_PROXY="10.10.242.6"
LOAD_BALANCER="10.10.242.55"

# specific settings for storage
ACCOUNT_HOSTS="10.10.242.6"
CONTAINER_HOSTS="10.10.242.6"
OBJECT_HOSTS="10.10.242.6"

# does the script have to create separate zones ?
# at the moment, a zone is a single group account-container-object
CREATE_ZONES=0

# Replication count
REPLICATION=3

# Partition power (2^n)
PARTITIONS=7
