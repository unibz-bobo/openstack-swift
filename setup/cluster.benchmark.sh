#!/bin/bash

# (C) 2014 Lorenzo Miori
#   Bachelor Thesis Project: middleware deployment and evaluation of a Raspberry Cluster
#
# Modified by Julian Sanin (2016)
#

# Get the proxy address for running the examples
source "$(dirname $0)/cluster.lib.sh"
source "$(dirname $0)/cluster.cfg.sh"

clusterInit "$CLUSTER_CONFIGURATION" 1

readonly LOAD_BALANCER=$(echo "$CLUSTER_BALANCER_IPS" | cut -d " " -f 1)

AUTHURL="http://$LOAD_BALANCER:8080/auth/v1.0/"
#AUTHURL="http://10.10.241.211:8080/auth/v1.0/"
USER="system:root"
KEY="testpass"
# NOTE: this number here is also related to available proxy servers (behind load balancer)
WORKERS=3

mkdir ssbench-logs

for t in very_small.scenario zero_byte_upload.scenario; do # `ls ssbench/scenarios`
    echo "$t"
    ssbench-master run-scenario -f ssbench/scenarios/$t -u 4 -c 80 -o 613 --pctile 50 --workers $WORKERS -V 1.0 -U $USER -K $KEY -A $AUTHURL 2>&1 | tee ssbench-logs/$t.log
done
