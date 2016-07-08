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

readonly CONTENT_LIST='
yjl
swman
patches
packages
load_balancer
configurations
cluster.cfg.sh
cluster.lib.sh
cluster.updater.sh
cluster.installer.sh
cluster.installer.node.sh
cluster.installer.proxy.sh
cluster.installer.storage.sh
cluster.installer.balancer.sh
stack_rsa
stack_rsa.pub
'

clusterUpdate() {
  local ip="$1"
  echo "Updating on '$ip'." | LSINFO | tee -a "$LOGS/$ip"
  for content in $CONTENT_LIST; do
    ( echo -n "Copying '$(dirname $0)/$content' to 'root@$ip' ... "; scp -i "$(dirname $0)/stack_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r "$content" root@$1: 2>&1 ) | LSDEBUG | tee -a "$LOGS/$ip"
  done
  echo "Done with '$ip'." | LSINFO | tee -a "$LOGS/$ip"
}

chmod 400 "$(dirname $0)/stack_rsa"
echo "Updating cluster nodes ..."
for ip in $CLUSTER_IPS; do
  clusterUpdate $ip &
done
wait

exit 0
