#!/bin/bash

source configuration-default.sh

DEVICES=( $PROXY_HOSTS )
MASTER_PROXY=${DEVICES[0]}

echo "##########################"
echo "First node to be setup is:"
echo "##########################"
echo $MASTER_PROXY
echo "##########################"

set +x

mkdir logs

function cleanup() {
    local host=$1
    echo "Cleaning up $host"
    ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$host "swift-init all stop ; rm -R /etc/swift ; mkdir -p /etc/swift ; chown -R swift:swift /etc/swift/" > logs/$host 2>&1
    echo "Cleanup done for $host"
}

function install {
    local host=$1
    echo "Installing $host"
    ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$host "swift-init all stop ; cd /root/ && /bin/bash setup-swift-distributed-subsystems.sh proxy" >> logs/$host 2>&1
    echo "Done with $host"
}

for device in $PROXY_HOSTS
do
    cleanup $device &
done

wait

ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$MASTER_PROXY "swift-init all stop ; cd /root/ && /bin/bash setup-swift-distributed-subsystems.sh proxy firstnode" >> logs/$MASTER_PROXY 2>&1

for device in $PROXY_HOSTS
do
    if [ "$device" != "$MASTER_PROXY" ]
    then
        install $device &
    fi
done

#echo "Setting up the load balancer"


wait
echo "Done Done"
