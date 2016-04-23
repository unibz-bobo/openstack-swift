#!/bin/bash

# pick the configuration parameters
source configuration-default.sh

STORAGE_HOSTS=$PROXY_HOSTS" "$ACCOUNT_HOSTS" "$CONTAINER_HOSTS" "$OBJECT_HOSTS

set +x

chmod 400 stack_rsa

STOP_ALL_CMD="swift-init object-replicator stop ; swift-init object-updater stop ; swift-init object-auditor stop; swift-init container-server stop; swift-init container-replicator stop; swift-init container-updater stop; swift-init container-auditor stop; swift-init container-info stop; swift-init container-sync stop; swift-init container-reconciler stop; swift-init account-server stop; swift-init account-replicator stop; swift-init account-updater stop; swift-init account-auditor stop; swift-init proxy stop"
START_ACCOUNT="swift-init account-server restart ; swift-init account-replicator restart ; swift-init account-updater restart ; swift-init account-auditor restart"
START_CONTAINER="swift-init container-server restart ; swift-init container-replicator restart ; swift-init container-updater restart ; swift-init container-auditor restart ; swift-init container-info restart ; swift-init container-sync restart ; swift-init container-reconciler restart"
START_OBJECT="swift-init object-server restart ; swift-init object-replicator restart ; swift-init object-updater restart ; swift-init object-auditor restart"
START_PROXY="swift-init proxy restart"

function start_proxy() {
    echo "Starting account on $1"
    ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$START_PROXY"
}

function start_account() {
    echo "Starting account on $1"    
    ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$START_ACCOUNT"
}

function start_container() {
    echo "Starting container on $1"    
    ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$START_CONTAINER"
}

function start_object() {
    echo "Starting object on $1"    
    ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$START_OBJECT"
}

function stop_all() {
    echo "Stopping all services on $1"    
    ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 "$STOP_ALL_CMD"
}

# NOTE: paralleling scp calls makes the deployment practically instant!

# "Start" stopping nodes

for host in $STORAGE_HOSTS
do
    stop_all $host &
done

wait

# Stopping nodes done, start services

for i in $ACCOUNT_HOSTS
do
    start_account $i &
done

for i in $CONTAINER_HOSTS
do
    start_container $i &
done

for i in $OBJECT_HOSTS
do
    start_object $i &
done

for i in $PROXY_HOSTS
do
    start_proxy $i &
done

wait # for threads to stop
