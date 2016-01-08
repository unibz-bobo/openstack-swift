#!/bin/bash

# PROXY_HOSTS="10.10.242.97 10.10.242.98 10.10.242.99"
# ACCOUNT_HOSTS="10.10.242.6"
# CONTAINER_HOSTS="10.10.242.7"
# OBJECT_HOSTS="10.10.242.8 10.10.242.9 10.10.242.10 10.10.242.11 10.10.242.12 10.10.242.45 10.10.242.46 10.10.242.47 10.10.242.48 10.10.242.49 10.10.242.50 10.10.242.51 10.10.242.52 10.10.242.53 10.10.242.54"

# pick the configuration parameters
source configuration-default.sh

STORAGE_HOSTS=$PROXY_HOSTS" "$ACCOUNT_HOSTS" "$CONTAINER_HOSTS" "$OBJECT_HOSTS

set +x

chmod 400 stack_rsa

CONTENT_LIST="configurations patches packages configuration-default.sh setup-swift-distributed-subsystems.sh"

function deploy() {
    echo "Updating on $1"
    scp -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r $CONTENT_LIST root@$1:
    echo "Done with $1"
}

# NOTE: paralleling scp calls makes the deployment practically instant!

for host in $STORAGE_HOSTS
do
    deploy $host &
done

wait
