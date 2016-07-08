#!/bin/bash

# (C) 2014 Lorenzo Miori
#   Bachelor Thesis Project: middleware deployment and evaluation of a Raspberry Cluster
#
# Modified by Julian Sanin (2016)
#

# This script will load the configuration file and set some constants.
# CLUSTER_BALANCER_IPS    ... the load balancer IP addresses.
# CLUSTER_PROXY_IPS       ... the proxy node IP addresses.
# CLUSTER_MASTER_PROXY_IP ... the IP address of the master proxy node.
# CLUSTER_ACCOUNT_IPS     ... the account node IP addresses.
# CLUSTER_CONTAINER_IPS   ... the container node IP addresses.
# CLUSTER_OBJECT_IPS      ... the object store node IP addresses.
# CLUSTER_STORAGE_IPS     ... the IP addresses of account, container & object nodes.
# CLUSTER_IPS             ... the all the above unique IP addresses combined.
# CLUSTER_NODE_IP         ... the IP address of the current node from where the script is running.
# CLUSTER_NODE_CPU_CORES  ... the number of CPU cores of the current node.
# CLUSTER_MASTER_PROXY_IP ... the IP address of the master proxy node.
#
# CLUSTER_SWIFT_RELEASE        ... OpenStack Swift server git release tag.
# CLUSTER_SWIFT_CLIENT_RELEASE ... OpenStack Swift client git release tag.
#
# CLUSTER_SSL_ENABLED ... (yes/no) if OpenSSL encription is enabled or not.
#
# CLUSTER_PARTITIONS   ... partition power (2^n).
# CLUSTER_REPLICATION  ... replication count.
# CLUSTER_CREATE_ZONES ... (yes/no) create zones, a zone is a single group account-container-object.
#
# CLUSTER_STORAGE_BLK_DEVICE ... (optional) use some other device than OS disk storage. The disk has already to be partitioned!
# CLUSTER_STORAGE_FILESYSTEM ... (XFS or F2FS) selected filesystem.
#
# CLUSTER_ACCOUNT_MAX_CONN   ... max. connections for rsyncd on account nodes.
# CLUSTER_CONTAINER_MAX_CONN ... max. connections for rsyncd on container nodes.
# CLUSTER_OBJECT_MAX_CONN    ... max. connections for rsyncd on object nodes.
#
# CLUSTER_ACCOUNT_MAX_AUDIT_THROUGHPUT   ... (accounts/sec) limit of account auditor.
# CLUSTER_CONTAINER_MAX_AUDIT_THROUGHPUT ... (containers/sec) limit of container auditor.
# CLUSTER_OBJECT_MAX_AUDIT_THROUGHPUT    ... (files/second) limit of object auditor.
# CLUSTER_OBJECT_MAX_AUDIT_BANDWIDTH     ... (bytes/second) limit of object auditor.
#
# CLUSTER_BALANCER_MAX_CONN ... max. connections from load balancer to each proxy node.

source "$(dirname $BASH_SOURCE)/swman/swman.lib.sh"

clusterInit() {
  local clusterCfgFile="$1" # path to xml file
  readonly VERBOSITY="$2"   # (0=off 1=some 2=all)
  [ "$VERBOSITY" -gt 0 ] && echo "Using configuration file '$clusterCfgFile'."
  # Make sure xmllint is installed.
  if [ "$ID_LIKE" = debian ]; then
    clusterGetPackage "libxml2-utils"
  elif [ "$ID_LIKE" = arch ]; then
    clusterGetPackage "libxml2"
  fi
  # Read configuration from file.
  readonly CLUSTER_BALANCER_IPS=$(clusterGetXmlSiblings /cluster/swift/balancer-server/node ip_address "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Load balancer IP addresses are: $CLUSTER_BALANCER_IPS"
  readonly CLUSTER_PROXY_IPS=$(clusterGetXmlSiblings /cluster/swift/proxy-server/node ip_address "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Proxy IP addresses are: $CLUSTER_PROXY_IPS"
  readonly CLUSTER_MASTER_PROXY_IP=$(echo "$CLUSTER_PROXY_IPS" | cut -d " " -f 1)
  [ "$VERBOSITY" -gt 1 ] && echo "Master proxy IP address is: $CLUSTER_MASTER_PROXY_IP"
  readonly CLUSTER_ACCOUNT_IPS=$(clusterGetXmlSiblings /cluster/swift/account-server/node ip_address "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Account IP addresses are: $CLUSTER_ACCOUNT_IPS"
  readonly CLUSTER_CONTAINER_IPS=$(clusterGetXmlSiblings /cluster/swift/container-server/node ip_address "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Container IP addresses are: $CLUSTER_CONTAINER_IPS"
  readonly CLUSTER_OBJECT_IPS=$(clusterGetXmlSiblings /cluster/swift/object-server/node ip_address "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Object store IP addresses are: $CLUSTER_OBJECT_IPS"
  local storageIPs="$CLUSTER_ACCOUNT_IPS$CLUSTER_CONTAINER_IPS$CLUSTER_OBJECT_IPS"
  readonly CLUSTER_STORAGE_IPS=$(echo $(echo -e "${storageIPs// /\\n}" | sort -u))
  [ "$VERBOSITY" -gt 1 ] && echo "All cluster storage node IPs are: $CLUSTER_STORAGE_IPS"
  local clusterIPs="$CLUSTER_BALANCER_IPS$CLUSTER_PROXY_IPS$CLUSTER_ACCOUNT_IPS$CLUSTER_CONTAINER_IPS$CLUSTER_OBJECT_IPS"
  readonly CLUSTER_IPS=$(echo $(echo -e "${clusterIPs// /\\n}" | sort -u))
  [ "$VERBOSITY" -gt 1 ] && echo "All cluster node IPs are: $CLUSTER_IPS"
  readonly CLUSTER_NODE_IP=$(clusterGetNodeIPs | cut -d " " -f 1)
  [ "$VERBOSITY" -gt 1 ] && echo "Current node IP address from where the script is running: $CLUSTER_NODE_IP"
  readonly CLUSTER_NODE_CPU_CORES=$(cat /proc/cpuinfo | grep -P "processor\t:" | wc -l)
  [ "$VERBOSITY" -gt 1 ] && echo "Current node has $CLUSTER_NODE_CPU_CORES CPU cores"
  #
  readonly CLUSTER_SWIFT_RELEASE=$(clusterGetXmlNode /cluster/swift/git-source/swift release "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Swift server release version is set to: $CLUSTER_SWIFT_RELEASE"
  readonly CLUSTER_SWIFT_CLIENT_RELEASE=$(clusterGetXmlNode /cluster/swift/git-source/python-swiftclient release "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Swift client release version is set to: $CLUSTER_SWIFT_CLIENT_RELEASE"
  #
  readonly CLUSTER_SSL_ENABLED="no" # At the moment, also because of benchmarking, we simply keep it off.
  [ "$VERBOSITY" -gt 1 ] && echo "OpenSSL encryption enabled: $CLUSTER_SSL_ENABLED"
  #
  readonly CLUSTER_PARTITIONS=$(clusterGetXmlNode /cluster/swift/node partition_count "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Cluster partition count (2^n) is set to: $CLUSTER_PARTITIONS"
  readonly CLUSTER_REPLICATION=$(clusterGetXmlNode /cluster/swift/node replication_count "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Cluster replication count is set to: $CLUSTER_REPLICATION"
  readonly CLUSTER_CREATE_ZONES=$(clusterGetXmlNode /cluster/swift/node create_zones "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Cluster create zones enabled: $CLUSTER_CREATE_ZONES"
  #
  readonly CLUSTER_STORAGE_BLK_DEVICE="$(clusterGetXmlNode /cluster/swift/storage block_device_path "$clusterCfgFile")"
  [ "$VERBOSITY" -gt 1 ] && ( echo -n "Cluster storage block device is set to: "; [ -z $CLUSTER_STORAGE_BLK_DEVICE ] && echo "loop"; [ ! -z $CLUSTER_STORAGE_BLK_DEVICE ] && echo "$CLUSTER_STORAGE_BLK_DEVICE"; )
  readonly CLUSTER_STORAGE_FILESYSTEM=$(clusterGetXmlNode /cluster/swift/storage filesystem "$clusterCfgFile")
  [ "$VERBOSITY" -gt 1 ] && echo "Cluster storage filesystem is set to: $CLUSTER_STORAGE_FILESYSTEM"
  #
  readonly CLUSTER_ACCOUNT_MAX_CONN=2   # TODO: increase value on multicore CPUs?
  [ "$VERBOSITY" -gt 1 ] && echo "Max. connections for syncronizing account nodes is set to: $CLUSTER_ACCOUNT_MAX_CONN"
  readonly CLUSTER_CONTAINER_MAX_CONN=4 # TODO: increase value on multicore CPUs?
  [ "$VERBOSITY" -gt 1 ] && echo "Max. connections for syncronizing container nodes is set to: $CLUSTER_CONTAINER_MAX_CONN"
  readonly CLUSTER_OBJECT_MAX_CONN=8    # TODO: increase value on multicore CPUs?
  [ "$VERBOSITY" -gt 1 ] && echo "Max. connections for syncronizing object nodes is set to: $CLUSTER_OBJECT_MAX_CONN"
  #
  readonly CLUSTER_ACCOUNT_MAX_AUDIT_THROUGHPUT=100   # TODO: increase value on multicore CPUs?
  [ "$VERBOSITY" -gt 1 ] && echo "Max. account auditor throughput is set to: $CLUSTER_ACCOUNT_MAX_AUDIT_THROUGHPUT accounts/sec"
  readonly CLUSTER_CONTAINER_MAX_AUDIT_THROUGHPUT=100 # TODO: increase value on multicore CPUs?
  [ "$VERBOSITY" -gt 1 ] && echo "Max. container auditor throughput is set to: $CLUSTER_CONTAINER_MAX_AUDIT_THROUGHPUT containers/sec"
  readonly CLUSTER_OBJECT_MAX_AUDIT_THROUGHPUT=50     # TODO: increase value on multicore CPUs?
  [ "$VERBOSITY" -gt 1 ] && echo "Max. object auditor throughput is set to: $CLUSTER_OBJECT_MAX_AUDIT_THROUGHPUT files/sec"
  readonly CLUSTER_OBJECT_MAX_AUDIT_BANDWIDTH=1000000 # TODO: increase value on multicore CPUs?
  [ "$VERBOSITY" -gt 1 ] && echo "Max. object auditor bandwidth is set to: $CLUSTER_OBJECT_MAX_AUDIT_BANDWIDTH bytes/sec"
  readonly CLUSTER_BALANCER_MAX_CONN=512
  [ "$VERBOSITY" -gt 1 ] && echo "Max. connections for load balancer is set to: $CLUSTER_BALANCER_MAX_CONN"
}

clusterGetPackage() {
  local package="$1"
  packageQuery "$package"
  if [ $? != 0 ]; then
    [ "$VERBOSITY" -gt 0 ] && echo "Installing package $package."
    runAsRoot packageInstall "$package"
    if [ $? != 0 ]; then
      [ "$VERBOSITY" -gt 0 ] && echo "$package could not be installed."
    fi
  else
    [ "$VERBOSITY" -gt 0 ] && echo "$package is already installed."
  fi
}

clusterGetXmlSiblings() {
  local xPathPrefix="$1"
  local xPathSibling="$2"
  local xmlFile="$3"
  local count=$(xmllint --xpath "count($xPathPrefix)" "$xmlFile")
  for (( i=1; i <= $count; i++ )); do
    echo -n $(xmllint --xpath "string($xPathPrefix[$i]/$xPathSibling)" "$xmlFile")" "
  done
}

clusterGetXmlNode() {
  local xPathPrefix="$1"
  local xPathNode="$2"
  local xmlFile="$3"
  local node=$(clusterGetXmlSiblings "$xPathPrefix" "$xPathNode" "$xmlFile")
  echo "$node" | cut -d " " -f 1
}

clusterIsRoot() {
  local script="$1"
  if [ `whoami` != "root" ]; then
    [ "$VERBOSITY" -gt 0 ] && echo "Please run '$script' as root or execute it with sudo!"
    exit -1
  fi
}

# Get all IP addresses without localhost address of
# the current node from where the script is executed.
clusterGetNodeIPs() {
  if [ "$ID_LIKE" = debian ]; then
    hostname -I
  elif [ "$ID_LIKE" = arch ]; then
    hostname -i
  fi
}
