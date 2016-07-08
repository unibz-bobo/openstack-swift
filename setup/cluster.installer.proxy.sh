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

# Set permissions.
chmod 644 stack_rsa.pub
chmod 600 stack_rsa

readonly KEY_FILE=$(readlink -m stack_rsa)

if [ "$1" == "firstnode" ]; then
  echo "Running this script on the first node"
  readonly IS_FIRST_NODE=1
else
  echo "Running on consequent (>1st) nodes"
  readonly IS_FIRST_NODE=0
fi

if [ $IS_FIRST_NODE -eq 1 ]; then
  echo "Generating ring random hash, will be replicated on the other nodes"
  cat >/etc/swift/swift.conf <<EOF
[swift-hash]
# random unique strings that can never change (DO NOT LOSE)
swift_hash_path_prefix = `od -t x8 -N 8 -A n </dev/random`
swift_hash_path_suffix = `od -t x8 -N 8 -A n </dev/random`
EOF

  # From 2nd node onwards (basically all nodes except the first) copy the basic configuration
  # NOTE: calls are parallelized to make things a lot faster!
  for storageIP in $CLUSTER_STORAGE_IPS; do
    if [ "$storageIP" != "$CLUSTER_NODE_IP" ]; then
      # NOTE: Folder creation is done in the updater/installer (refer to it)
      scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE /etc/swift/swift.conf root@$storageIP:/etc/swift/ &
    fi
  done
  wait # important to wait for completion of scp calls above

  for proxyIP in $CLUSTER_PROXY_IPS; do
    if [ "$proxyIP" != "$CLUSTER_NODE_IP" ]; then
      # NOTE: Folder creation is done in the updater/installer (refer to it)
      scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE /etc/swift/swift.conf root@$proxyIP:/etc/swift/ &
    fi
  done
  wait # important to wait for completion of scp calls above

fi # End of firstnode setup.

echo "Installing a proxy node with $CLUSTER_NODE_CPU_CORES CPU cores (:= spawn processes)"
echo "Quitting running instances..."
# Cleanup any running instance, if any
swift-init proxy stop

# SSL testing support
cd /etc/swift
# This step is needed if SSL is turned on.
# At the moment, also because of benchmarking, we simply keep it off
if [ "$CLUSTER_SSL_ENABLED" == "yes" ]; then
  openssl req -new -x509 -nodes -out cert.crt -keyout cert.key
fi

# memcached listening
# NOTE problems in starting memcached means authorization errors (curl, client...)
if [ "$ID_LIKE" = debian ]; then
  sed -i -e "s#-l [[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+#-l $CLUSTER_NODE_IP#" /etc/memcached.conf
  serviceStart memcached
elif [ "$ID_LIKE" = arch ]; then
  # There is no memcached.conf file installed.
  # Reuse and modify memcached.service file instead.
  cp /usr/lib/systemd/system/memcached.service /usr/lib/systemd/system/swift-memcached.service
  sed -i -e "s#-l [[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+#-l $CLUSTER_NODE_IP#" /usr/lib/systemd/system/swift-memcached.service
  serviceStart swift-memcached
fi

join_port() {
    local SEPARATOR="$1"
    shift
    local PORT="$1"
    shift
    V=""
    while (( "$#" ))
    do
        if [ -z $V ]
        then
        V="$1:$PORT"
        else
        V=$V$SEPARATOR"$1:$PORT"
        fi

        shift
    done
    echo $V
}

# create the configuration for the proxy server
cat >/etc/swift/proxy-server.conf <<EOF
[DEFAULT]
swift_dir = /etc/swift
bind_ip = 0.0.0.0
bind_port = 8080
bind_timeout = 30
# pre-forked processes. No more than 1 on the Raspberry Pi 1 ...
workers = $CLUSTER_NODE_CPU_CORES
user = swift
#expiring_objects_container_divisor = 86400
#cert_file = /etc/swift/cert.crt
#key_file = /etc/swift/cert.key

# You can specify default log routing here if you want:
log_name = swift
log_facility = LOG_LOCAL0
log_level = INFO

[pipeline:main]
pipeline = catch_errors gatekeeper healthcheck proxy-logging cache container_sync tempauth proxy-logging proxy-server

#pipeline = catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk tempurl ratelimit crossdomain authtoken keystoneauth tempauth  formpost #staticweb container-quotas account-quotas slo dlo proxy-logging $

[app:proxy-server]
use = egg:swift#proxy
allow_account_management = true
account_autocreate = true
set log_name = swift-proxy-server
set log_facility = LOG_LOCAL0
set log_level = DEBUG
set access_log_name = swift-proxy-server
set access_log_facility = LOG_LOCAL0
set access_log_level = DEBUG
set log_headers = True
# How long the proxy server will wait on responses from the a/c/o servers.
# This is especially important in simple single node configurations
node_timeout = 30

[filter:proxy-logging]
use = egg:swift#proxy_logging

[filter:tempauth]
use = egg:swift#tempauth
# The reseller prefix will verify a token begins with this prefix before even
# attempting to validate it. Also, with authorization, only Swift storage
# accounts with this prefix will be authorized by this middleware. Useful if
# multiple auth systems are in use for one Swift cluster.
# user_<account>_<user> = <key>  [group] [other options] [storage_url]
reseller_prefix = TEMPAUTH
user_system_root = testpass .admin .reseller_admin
user_admin_admin = admin .admin .reseller_admin

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:cache]
use = egg:swift#memcache
# Multiple servers must be comma separated (all with port number too)
memcache_servers = `join_port , 11211 $CLUSTER_PROXY_IPS`
set log_name = cache

[filter:swiftauth]
paste.filter_factory = keystone.middleware.swift_auth:filter_factory
operator_roles = admin, swiftoperator
is_admin = true

[filter:gatekeeper]
use = egg:swift#gatekeeper

[filter:container_sync]
use = egg:swift#container_sync

[filter:bulk]
use = egg:swift#bulk

[filter:authtoken]
paste.filter_factory = keystone.middleware.auth_token:filter_factory
service_protocol = http
service_host = $CLUSTER_NODE_IP
service_port = 5000
auth_host = $CLUSTER_NODE_IP
auth_port = 35357
auth_protocol = http
auth_uri = http://$CLUSTER_NODE_IP:5000/
admin_tenant_name = service
admin_user = swift
admin_password = swift
delay_auth_decision = 0

EOF

# If we are setting up another proxy node, we don't have to redo all the balancing
if [ $IS_FIRST_NODE -eq 1 ]; then
  # create the account, container and object rings
  cd /etc/swift
  rm -f account.builder account.ring.gz backups/account.builder backups/account.ring.gz
  rm -f container.builder container.ring.gz backups/container.builder container.ring.gz
  rm -f object.builder object.ring.gz backups/object.builder backups/object.ring.gz
  rm -f *.builder *.ring.gz backups/*.builder backups/*.ring.gz

  swift-ring-builder account.builder create $CLUSTER_PARTITIONS $CLUSTER_REPLICATION 1
  swift-ring-builder container.builder create $CLUSTER_PARTITIONS $CLUSTER_REPLICATION 1
  swift-ring-builder object.builder create $CLUSTER_PARTITIONS $CLUSTER_REPLICATION 1

  # setting up zones. Basically this has to be done for every storage node, zone
  # increments by 1 everytime
  ZONE=1
  readonly WEIGHT=100.0  # relative weight (higher for bigger/faster disks)
  readonly DEVICE=sdb1

  for ip in $CLUSTER_ACCOUNT_IPS; do
    swift-ring-builder account.builder add z$ZONE-$ip:6002/$DEVICE $WEIGHT
    if [ "$CLUSTER_CREATE_ZONES" = yes ]; then
      echo "ZONE=$ZONE"
      ZONE=$(($ZONE+1))
    fi
  done

  ZONE=1
  for ip in $CLUSTER_CONTAINER_IPS; do
    swift-ring-builder container.builder add z$ZONE-$ip:6001/$DEVICE $WEIGHT
    if [ "$CLUSTER_CREATE_ZONES" = yes ]; then
      ZONE=$(($ZONE+1))
    fi
  done

  ZONE=1
  for ip in $CLUSTER_OBJECT_IPS; do
    swift-ring-builder object.builder add z$ZONE-$ip:6000/$DEVICE $WEIGHT
    if [ "$CLUSTER_CREATE_ZONES" = yes ]; then
      ZONE=$(($ZONE+1))
    fi
  done

  # verify ring content for each ring
  swift-ring-builder account.builder
  swift-ring-builder container.builder
  swift-ring-builder object.builder

  # rebalance the rings
  swift-ring-builder account.builder rebalance
  swift-ring-builder container.builder rebalance
  swift-ring-builder object.builder rebalance

  # now it's time to copy around rings...
  sleep 5 # Maybe use sync instead?
  echo "Listing directory /etc/swift"
  ls -l /etc/swift
  for storageIP in $CLUSTER_STORAGE_IPS; do
    if [ "$storageIP" != "$CLUSTER_NODE_IP" ]; then
      scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE /etc/swift/*.ring.gz root@$storageIP:/etc/swift &
    fi
  done
  wait # important to wait for completion of scp calls above

  for proxyIP in $CLUSTER_PROXY_IPS; do
    if [ "$proxyIP" != "$CLUSTER_NODE_IP" ]; then
      scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE /etc/swift/*.ring.gz root@$proxyIP:/etc/swift &
    fi
  done
  wait # important to wait for completion of scp calls above
fi # End of firstnode setup.

# Copy the account.ring.gz, container.ring.gz, and object.ring.gz files to each of the Proxy and Storage nodes in /etc/swift.

chown -R swift:swift /etc/swift

swift-init proxy restart

exit 0
