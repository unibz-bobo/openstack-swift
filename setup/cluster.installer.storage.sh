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

echo "Installing a storage node with $CLUSTER_NODE_CPU_CORES CPU (:= spawned processes)"
#echo "Quitting running instances..."
## Stop object server instance(s)
#swift-init object-server stop
#swift-init object-replicator stop
#swift-init object-updater stop
#swift-init object-auditor stop
#
## Stop container server instance(s)
#swift-init container-server stop
#swift-init container-replicator stop
#swift-init container-updater stop
#swift-init container-auditor stop
#swift-init container-info stop
#swift-init container-sync stop
#swift-init container-reconciler stop
#
## Stop account server instance(s)
#swift-init account-server stop
#swift-init account-replicator stop
#swift-init account-updater stop
#swift-init account-auditor stop
#
#swift-init proxy stop

if [ -b "$CLUSTER_STORAGE_BLK_DEVICE" ]; then
  echo "Block device $CLUSTER_STORAGE_BLK_DEVICE exists, assuming to be using it."
  readonly SSD_ENABLED="1"
  readonly STORAGE_LOOP="0"
  readonly STORAGE_DISK="$CLUSTER_STORAGE_BLK_DEVICE"
else
  echo "No block device found. Using loop device on /swift-storage instead."
  readonly SSD_ENABLED="0"
  readonly STORAGE_LOOP="1"
  readonly STORAGE_DISK="/swift-storage"
fi

# For every device on the node, setup the XFS volume (/dev/sdb is used as an example), add mounting option inode64 when your disk is bigger than 1TB to archive a better performance.
# Check if a specific filesystem has been chosen. defaults to "XFS"
if [ -z $CLUSTER_STORAGE_FILESYSTEM ]; then
  # If no filesystem is specified, default it to "XFS"
  echo "No storage filesystem specified, defaulting to XFS."
  readonly FILESYSTEM="XFS"
else
  echo "Storage filesystem is set to $CLUSTER_STORAGE_FILESYSTEM."
  readonly FILESYSTEM="$CLUSTER_STORAGE_FILESYSTEM"
fi

if [ "$STORAGE_LOOP" = "1" ]; then
  rm -f $STORAGE_DISK
  # allocate filesystem image space (filesystem generic)
  echo "Using 1024MB file for $STORAGE_DISK."
  truncate -s 1024M $STORAGE_DISK
fi

# prepare mount point
mkdir -p /srv/node/sdb1

echo "Formatting $STORAGE_DISK with $FILESYSTEM."
case "$FILESYSTEM" in
  "XFS" )
    # create and format filesystem
    mkfs.xfs -f -i size=1024 $STORAGE_DISK
    if [ "$STORAGE_LOOP" = "1" ]; then
      # add fstab entry for the specific filesystem
      echo "$STORAGE_DISK /srv/node/sdb1 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
    else
    # add fstab entry for the specific filesystem
      echo "$STORAGE_DISK /srv/node/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
    fi
  ;;
  "F2FS" )
    # create and format filesystem
    mkfs.f2fs $STORAGE_DISK
    # add fstab entry for the specific filesystem
    if [ "$STORAGE_LOOP" = "1" ]; then
      echo "$STORAGE_DISK /srv/node/sdb1 f2fs loop,noatime,nodiratime 0 0" >> /etc/fstab
    else
      echo "$STORAGE_DISK /srv/node/sdb1 f2fs noatime,nodiratime 0 0" >> /etc/fstab
    fi
  ;;
  "EXT4" )
    echo "EXT4 Filesystem has been selected"
    echo "STUB! ABORTING!"
    exit -1
  ;;
  "ROOTFS" )
    echo "ROOTFS Filesystem has been selected"
    echo "STUB! ABORTING!"
    exit -1
  ;;
  * )
    echo "Unknown filesystem selected -$FILESYSTEM- [ XFS | F2FS | EXT4 | ROOTFS ]. Aborting."
    exit 1
  ;;
esac

# mount the freshly created filesystem
echo "Mounting $STORAGE_DISK as:"
cat /etc/fstab | grep /srv/node/sdb1
mount $STORAGE_DISK

# swift owns (its) world
chown swift:swift -R /srv/node

# clean some stuff up!
rm -rf /var/log/swift
mkdir -p /var/log/swift

find /var/cache/swift* -type f -name *.recon -exec rm -f {} \;

# Create /etc/rsyncd.conf:

# in the future (3.1.0 version) there will be this possibility
# to save a little time...
#reverse lookup = no
cat >/etc/rsyncd.conf <<EOF
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = 127.0.0.1

[account]
max connections = $CLUSTER_ACCOUNT_MAX_CONN
path = /srv/node/
read only = false
lock file = /var/lock/account.lock

[container]
max connections = $CLUSTER_CONTAINER_MAX_CONN
path = /srv/node/
read only = false
lock file = /var/lock/container.lock

[object]
max connections = $CLUSTER_OBJECT_MAX_CONN
path = /srv/node/
read only = false
lock file = /var/lock/object.lock
EOF

if [ "$ID_LIKE" = debian ]; then
  # Edit the RSYNC_ENABLE= line in /etc/default/rsync:
  perl -pi -e 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync
  # Start rsync daemon:
  serviceStart rsync
elif [ "$ID_LIKE" = arch ]; then
  # Is there some other config file?
  serviceStart rsyncd
fi

# Create /etc/swift/account-server.conf:
cat >/etc/swift/account-server.conf <<EOF
[DEFAULT]
swift_dir = /etc/swift
devices = /srv/node
user = swift
bind_ip = $CLUSTER_NODE_IP
bind_port = 6002
workers = $CLUSTER_NODE_CPU_CORES
db_preallocation = off

[pipeline:main]
pipeline = account-server

[app:account-server]
use = egg:swift#account

[account-replicator]

[account-auditor]
accounts_per_second = $CLUSTER_ACCOUNT_MAX_AUDIT_THROUGHPUT

[account-reaper]
EOF

# Create /etc/swift/container-server.conf:
cat >/etc/swift/container-server.conf <<EOF
[DEFAULT]
swift_dir = /etc/swift
devices = /srv/node
user = swift
bind_ip = $CLUSTER_NODE_IP
bind_port = 6001
workers = $CLUSTER_NODE_CPU_CORES
db_preallocation = off

[pipeline:main]
pipeline = container-server

[app:container-server]
use = egg:swift#container

[container-replicator]

[container-updater]

[container-auditor]
containers_per_second = $CLUSTER_CONTAINER_MAX_AUDIT_THROUGHPUT

[container-sync]
EOF

# Create /etc/swift/object-server.conf:
cat >/etc/swift/object-server.conf <<EOF
[DEFAULT]
swift_dir = /etc/swift
devices = /srv/node
user = swift
bind_ip = $CLUSTER_NODE_IP
bind_port = 6000
workers = $CLUSTER_NODE_CPU_CORES
db_preallocation = off
mount_check = false

[pipeline:main]
pipeline = object-server

[app:object-server]
use = egg:swift#object

[object-replicator]

[object-updater]

[object-auditor]
files_per_second = $CLUSTER_OBJECT_MAX_AUDIT_THROUGHPUT
bytes_per_second = $CLUSTER_OBJECT_MAX_AUDIT_BANDWIDTH
EOF

#Start the storage services. If you use this command, it will try to start every service for which a configuration file exists, and throw a warning for any configuration files which don’t exist:
# HACK ?
# There are some default (?) configuration files
# in the *-server folder(s) that makes ghost processes to be forked
# Since they are not used at all and moreover owned by "pi" user, simply rename these folder(s)
cd /etc/swift
rm -Rf unused-account-server
mv -f account-server unused-account-server
rm -Rf unused-account-server
mv -f container-server unused-container-server
rm -Rf unused-container-server
mv -f object-server unused-container-server

for ip in $CLUSTER_ACCOUNT_IPS; do
  if [ "$CLUSTER_NODE_IP" == "$ip" ]; then
    swift-init account-server restart
    swift-init account-replicator restart
    swift-init account-updater restart
    swift-init account-auditor restart
  fi
done
for ip in $CLUSTER_CONTAINER_IPS; do
  if [ "$CLUSTER_NODE_IP" == "$ip" ]; then
    swift-init container-server restart
    swift-init container-replicator restart
    swift-init container-updater restart
    swift-init container-auditor restart
    swift-init container-info restart
    swift-init container-sync restart
    swift-init container-reconciler restart
  fi
done
for ip in $CLUSTER_OBJECT_IPS; do
  if [ "$CLUSTER_NODE_IP" == "$ip" ]; then
    swift-init object-server restart
    swift-init object-replicator restart
    swift-init object-updater restart
    swift-init object-auditor restart
  fi
done

# Note: this is a workaround for deployment on a single (or localhost) machine
# Proxy server gets stopped in the previous step, so here it is time to
# turn it on again
if [ "$CLUSTER_MASTER_PROXY_IP" == "$CLUSTER_NODE_IP" ]; then
  swift-init proxy restart
fi
# Do not forget also to restart the other proxies, if
# other services are being installed on them as well
for ip in $CLUSTER_PROXY_IPS; do
  if [ "$CLUSTER_NODE_IP" == "$ip" ]; then
    swift-init proxy restart
  fi
done
# Or, if you want to start them one at a time, run them as below. Note that if the server program in question generates any output on its stdout or stderr, swift-init has already redirected the command’s output to /dev/null. If you encounter any difficulty, stop the server and run it by hand from the command line. Any server may be started using “swift-$SERVER-$SERVICE /etc/swift/$SERVER-config”, where $SERVER might be object, continer, or account, and $SERVICE might be server, replicator, updater, or auditor.
# swift-init object-server start
# swift-init object-replicator start
# swift-init object-updater start
# swift-init object-auditor start
# swift-init container-server start
# swift-init container-replicator start
# swift-init container-updater start
# swift-init container-auditor start
# swift-init account-server start
# swift-init account-replicator start
# swift-init account-auditor start

exit 0
