#!/bin/bash

# (C) 2014 Lorenzo Miori
#   Bachelor Thesis Project: middleware deployment and evaluation of a Raspberry Cluster
#
# Modified by Julian Sanin (2016)
#

# This script will update the needed setup files on each cluster node.
# Be sure that the SSH keys are already installed on each node.

set -u

source "$(dirname $0)/cluster.lib.sh"
source "$(dirname $0)/cluster.cfg.sh"
source "$(dirname $0)/yjl/log.sh"

LS_LEVEL=LS_DEBUG_LEVEL

clusterInit "$CLUSTER_CONFIGURATION" 1

readonly LOGS="$(dirname $0)/logs"
mkdir -p "$LOGS"

clusterCleanup() {
  local ip="$1"
  echo "Cleaning up '$ip'." | LSINFO | tee -a "$LOGS/$ip"
  ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$ip "swift-init all stop; rm -R /etc/swift; mkdir -p /etc/swift; chown -R swift:swift /etc/swift/" 2>&1 | LSDEBUG | tee -a "$LOGS/$ip"
  echo "Cleanup done for '$ip'." | LSINFO | tee -a "$LOGS/$ip"
}

clusterInstall() {
  local ip="$1"
  echo "Installing '$ip'." | LSINFO | tee -a "$LOGS/$ip"
  ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$ip "cd /root/ && /bin/bash cluster.installer.node.sh" 2>&1 | LSDEBUG | tee -a "$LOGS/$ip"
  echo "Installing done with '$ip'." | LSINFO | tee -a "$LOGS/$ip"
}

clusterInstallProxy() {
  local ip="$1"
  local option="$2"
  ( echo -n "Installing proxy '$ip'"; [ ! -z $option ] && echo -n " as $option"; echo "."; ) | LSINFO | tee -a "$LOGS/$ip"
  ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$ip "cd /root/ && /bin/bash cluster.installer.proxy.sh $option" 2>&1 | LSDEBUG | tee -a "$LOGS/$ip"
  echo "Installing proxy done with '$ip'." | LSINFO | tee -a "$LOGS/$ip"
}

clusterInstallStorage() {
  local ip="$1"
  echo "Installing storage '$ip'." | LSINFO | tee -a "$LOGS/$ip"
  ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$ip "cd /root/ && /bin/bash cluster.installer.storage.sh" 2>&1 | LSDEBUG | tee -a "$LOGS/$ip"
  echo "Installing storage done with '$ip'." | LSINFO | tee -a "$LOGS/$ip"
}

clusterInstallBalancer() {
  local ip="$1"
  echo "Installing load balancer '$ip'." | LSINFO | tee -a "$LOGS/$ip"
  ssh -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$ip "cd /root/ && /bin/bash cluster.installer.balancer.sh" 2>&1 | LSDEBUG | tee -a "$LOGS/$ip"
  echo "Installing load balancer done with '$ip'." | LSINFO | tee -a "$LOGS/$ip"
}

chmod 400 "$(dirname $0)/stack_rsa"
echo "Cleaning up cluster nodes ..."
for ip in $CLUSTER_IPS; do
  clusterCleanup $ip &
done
wait

# Install on each node the OpenStack Swift environment.
echo "Installing cluster nodes ..."
for ip in $CLUSTER_IPS; do
  clusterInstall $ip &
done
wait

# Install proxies.
echo "Installing cluster proxy nodes ..."
clusterInstallProxy $CLUSTER_MASTER_PROXY_IP firstnode
for ip in $CLUSTER_PROXY_IPS; do
  if [ "$ip" != "$CLUSTER_MASTER_PROXY_IP" ]; then
    clusterInstallProxy $ip node &
  fi
done
wait

# Install storage nodes.
echo "Installing cluster storage nodes ..."
for ip in $CLUSTER_STORAGE_IPS; do
  clusterInstallStorage $ip &
done
wait

# Install load balancer nodes.
echo "Installing cluster load balancer nodes ..."
for ip in $CLUSTER_BALANCER_IPS; do
  clusterInstallBalancer $ip &
done
wait

exit 0
