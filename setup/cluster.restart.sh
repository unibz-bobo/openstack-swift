#!/bin/bash

# (C) 2014 Lorenzo Miori
#   Bachelor Thesis Project: middleware deployment and evaluation of a Raspberry Cluster
#
# Modified by Julian Sanin (2016)
#

set -u

# pick the configuration parameters
source "$(dirname $0)/cluster.lib.sh"
source "$(dirname $0)/cluster.cfg.sh"
source "$(dirname $0)/yjl/log.sh"

LS_LEVEL=LS_DEBUG_LEVEL

clusterInit "$CLUSTER_CONFIGURATION" 1

readonly LOGS="$(dirname $0)/logs"
mkdir -p "$LOGS"


chmod 400 "$(dirname $0)/stack_rsa"

#STOP_ALL_CMD="swift-init all stop; killall haproxy"
STOP_ALL_CMD="swift-init object-replicator stop ; swift-init object-updater stop ; swift-init object-auditor stop; swift-init container-server stop; swift-init container-replicator stop; swift-init container-updater stop; swift-init container-auditor stop; swift-init container-info stop; swift-init container-sync stop; swift-init container-reconciler stop; swift-init account-server stop; swift-init account-replicator stop; swift-init account-updater stop; swift-init account-auditor stop; swift-init proxy stop; killall haproxy"
START_ACCOUNT="swift-init account-server restart ; swift-init account-replicator restart ; swift-init account-updater restart ; swift-init account-auditor restart"
START_CONTAINER="swift-init container-server restart ; swift-init container-replicator restart ; swift-init container-updater restart ; swift-init container-auditor restart ; swift-init container-info restart ; swift-init container-sync restart ; swift-init container-reconciler restart"
START_OBJECT="swift-init object-server restart ; swift-init object-replicator restart ; swift-init object-updater restart ; swift-init object-auditor restart"
START_PROXY="swift-init proxy restart"
START_BALANCER="haproxy -f /etc/haproxy/haproxy.cfg -D"

function start_proxy() {
    echo "Starting proxy on $1" | tee -a "$LOGS/$1"
    ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$START_PROXY" 2>&1 | LSDEBUG | tee -a "$LOGS/$1"
}

function start_account() {
    echo "Starting account on $1" | tee -a "$LOGS/$1"
    ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$START_ACCOUNT" 2>&1 | LSDEBUG | tee -a "$LOGS/$1"
}

function start_container() {
    echo "Starting container on $1" | tee -a "$LOGS/$1"
    ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$START_CONTAINER" 2>&1 | LSDEBUG | tee -a "$LOGS/$1"
}

function start_object() {
    echo "Starting object on $1" | tee -a "$LOGS/$1"
    ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$START_OBJECT" 2>&1 | LSDEBUG | tee -a "$LOGS/$1"
}

function start_balancer() {
    echo "Starting balancer on $1" | tee -a "$LOGS/$1"
    ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$START_BALANCER" 2>&1 | LSDEBUG | tee -a "$LOGS/$1"
}

function stop_all() {
    echo "Stopping all services on $1" | tee -a "$LOGS/$1"
    ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$STOP_ALL_CMD" 2>&1 | LSDEBUG | tee -a "$LOGS/$1"
}

# NOTE: paralleling scp calls makes the deployment practically instant!

# "Start" stopping nodes

for host in $CLUSTER_IPS; do
    stop_all $host &
done
wait

# Stopping nodes done, start services

for i in $CLUSTER_ACCOUNT_IPS; do
    start_account $i &
done

for i in $CLUSTER_CONTAINER_IPS; do
    start_container $i &
done

for i in $CLUSTER_OBJECT_IPS; do
    start_object $i &
done
wait

for i in $CLUSTER_PROXY_IPS; do
    start_proxy $i &
done
wait

for i in $CLUSTER_BALANCER_IPS; do
    start_balancer $i &
done
wait # for threads to stop

exit 0
