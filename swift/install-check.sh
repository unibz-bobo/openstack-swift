#!/bin/bash

# pick the configuration parameters
source configuration-default.sh

STORAGE_HOSTS=$PROXY_HOSTS" "$ACCOUNT_HOSTS" "$CONTAINER_HOSTS" "$OBJECT_HOSTS

set +x

LATEST_MD5=""

for host in $STORAGE_HOSTS
do
    CONTENT=$(ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$host 'md5sum /etc/swift/*.ring.gz')
    echo $CONTENT
    if [ ! -z "$LATEST_MD5" ]
    then
        if [ "$CONTENT" != "$LATEST_MD5" ]
        then
            echo "Inconsistent configuration on $host"
            exit 1
        fi
    fi
    LATEST_MD5=$CONTENT
done

exit 0
