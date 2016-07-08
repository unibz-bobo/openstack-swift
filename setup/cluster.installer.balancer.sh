#!/bin/bash

# (C) 2014 Lorenzo Miori
#   Bachelor Thesis Project: middleware deployment and evaluation of a Raspb$
#
# Modified by Julian Sanin (2016)
#

# This script will install OpenStack Swift on each cluster node.

set -u

source "$(dirname $0)/cluster.lib.sh"
source "$(dirname $0)/cluster.cfg.sh"

clusterInit "$CLUSTER_CONFIGURATION" 1

clusterIsRoot "$0"

readonly CLUSTER_SWIFT_IPS=$(echo $(echo -e "${CLUSTER_PROXY_IPS// /\\n}\n${CLUSTER_STORAGE_IPS// /\\n}" | sort -u))

# Install load balancer only on non OpenStack Swift nodes.
if [[ "$CLUSTER_SWIFT_IPS"  != *$CLUSTER_NODE_IP* ]]; then
  echo "Installing load balancer on $CLUSTER_NODE_IP"
  clusterGetPackage haproxy
  cp load_balancer/haproxy_template.cfg load_balancer/haproxy.cfg.tmp
  i=0
  for ip in $CLUSTER_PROXY_IPS; do
    echo "    server s$i $ip:8080 maxconn $CLUSTER_BALANCER_MAX_CONN" >> load_balancer/haproxy.cfg.tmp
    i=$((i+1))
  done
  cp load_balancer/haproxy.cfg.tmp /etc/haproxy/haproxy.cfg
  rm load_balancer/haproxy.cfg.tmp
  killall haproxy
  haproxy -f /etc/haproxy/haproxy.cfg -D
else
  echo "Not installing load balancer on $CLUSTER_NODE_IP"
fi
echo "Done installing the load balancer"

exit 0
