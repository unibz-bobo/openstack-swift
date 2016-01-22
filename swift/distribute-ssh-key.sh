#!/bin/bash

# pick the configuration parameters
source configuration-default.sh

STORAGE_HOSTS=$PROXY_HOSTS" "$ACCOUNT_HOSTS" "$CONTAINER_HOSTS" "$OBJECT_HOSTS

set +x

chmod 400 stack_rsa

function dropSshKey() {
  echo "Distributing SSH key on host $1"
  ssh-copy-id -i stack_rsa.pub pi@$1
  ssh -i stack_rsa pi@$1 "sudo cp -r /home/pi/.ssh/ /root/; sudo chown root:root /root/.ssh"
}

for host in $STORAGE_HOSTS; do
  dropSshKey $host
done
