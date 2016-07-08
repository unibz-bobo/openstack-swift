#!/bin/bash
#
# Project: Thesis !
# Lorenzo Miori (C) 2014
#
# Modified by Julian Sanin (2016)
#

# Get the proxy address for running the examples
source "$(dirname $0)/../cluster.lib.sh"
source "$(dirname $0)/../cluster.cfg.sh"

clusterInit "$CLUSTER_CONFIGURATION" 1

readonly LOAD_BALANCER=$(echo "$CLUSTER_BALANCER_IPS" | cut -d " " -f 1)

# Authentication URL
URL_AUTHENTICATION="http://$LOAD_BALANCER:8080/auth/v1.0/"

# Authentication user
USER_AUTHENTICATION="system:root"

# Authentication key
KEY_AUTHENTICATION="testpass"
