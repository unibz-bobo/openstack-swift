#!/bin/bash

# (C) 2014 Lorenzo Miori
#   Bachelor Thesis Project: middleware deployment and evaluation of a Raspberry Cluster
#
# Modified by Julian Sanin (2016)
#

# This script will install the SSH keys for the OpenStack Swift deployment onto the cluster.
# Make sure that each node has installed and activated a SSH server!

set -u

source "$(dirname $0)/swman/swman.lib.sh"
source "$(dirname $0)/cluster.lib.sh"
source "$(dirname $0)/cluster.cfg.sh"

clusterInit "$CLUSTER_CONFIGURATION" 1

chmod 400 "$(dirname $0)/stack_rsa"
echo "Distributing cluster SSH key ..."
for ip in $CLUSTER_IPS; do
  if [ "$CLUSTER_NODE_IP" = $ip ]; then
    echo "Checking SSH server installation for localhost node with IP $CLUSTER_NODE_IP ..."
    # Assuming that you want to use also your local PC we install the SSH server for you.
    if [ "$ID_LIKE" = debian ]; then
      clusterGetPackage openssh-server
    elif [ "$ID_LIKE" = arch ]; then
      clusterGetPackage openssh
      serviceStatus sshd
      if [ $? != 0 ]; then
        echo "Enabling SSH server (you may be asked for the user password) ..."
        runAsRoot serviceStart sshd
      fi
    fi
  fi
  echo -n "Enter SSH user for node $ip (you may be asked for the user password): "
  read usr
  ssh-copy-id -i "$(dirname $0)/stack_rsa.pub" $usr@$ip
  echo "Installing SSH key for root user (you may be asked again for the user password) ..."
  ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t $usr@$ip "sudo cp -r /home/$usr/.ssh /root/; sudo chown root:root /root/.ssh"
done

exit 0
