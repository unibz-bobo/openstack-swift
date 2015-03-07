#!/bin/bash

source configuration-default.sh

STORAGE_HOSTS=$ACCOUNT_HOSTS" "$CONTAINER_HOSTS" "$OBJECT_HOSTS

set +x

mkdir logs

function install {
    echo "Installing $host"
    ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$host "swift-init all stop ; cd /root/ && /bin/bash setup-swift-distributed-subsystems.sh storage" > logs/$host 2>&1
    echo "Done with $host"
}

for host in $STORAGE_HOSTS
do
    install &
done

wait
echo "Done Done"
