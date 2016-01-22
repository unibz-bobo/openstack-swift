#!/bin/bash

#
#   Inspiration and main steps from
#   http://docs.openstack.org/developer/swift/howto_installmultinode.html
#   http://prosuncsedu.wordpress.com/2014/02/24/tempauth-a-lightweight-authentication-method-in-openstack/
#
#   As well as other official documentation and tutorials
#
#   ...but heaviliy modified and scripted

# (C) 2014 Lorenzo Miori
#   Bachelor Thesis Project: middleware deployment and evaluation of a Raspberry Cluster

echo "===================================="
echo "Starting something big..."
echo "In the meantime enjoy a moment of wisdom"
echo "Never - ever - rely on default values if they are valuable and critical"
echo "Trust me, not as engineer, nor as expert, but as poor's man debug advisor"
echo "===================================="

# At least for initial debugging, turn echoing of commands on
set -x

isRoot() {
  if [ `whoami` != "root" ]; then
    echo "Please run '$0' as root or execute it with sudo!"
    exit -1
  fi
}

getPackage() {
  local package=$1
  if [ -z "`dpkg -s $package 2> /dev/null | grep 'installed'`" ]; then
    apt-get --yes --force-yes -q=2 install $package
  else
    echo "$package is already installed."
  fi
  return 0
}

function join {
    local IFS="$1"
    shift
    echo "$*"
}

function join_port {
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

# Enums
NODE_TYPE_PROXY="proxy"
NODE_TYPE_STORAGE="storage"

# Settings
SSL_ENABLED="no" # turning it on also requires manual addition to proxy-server.conf for the moment !

# Params
if [ $# -eq 0 ]
then
    echo "Please select the target type [ storage | proxy ] [firstnode]"
    exit 1
fi

# this are the possibilities...
# either you install a proxy node or a storage node
case "$1" in

    "$NODE_TYPE_PROXY" )
        echo "Installing a proxy node"
        NODE_TYPE=$NODE_TYPE_PROXY
    ;;

    "$NODE_TYPE_STORAGE" )
        echo "Installing a storage node"
        NODE_TYPE=$NODE_TYPE_STORAGE
    ;;

    * )
        echo "Unknown installation type [ proxy | storage ]. Aborting."
        exit 1
    ;;

esac

echo "Generic node setup starting"
if [ "$2" == "firstnode" ]
then
    echo "Running this script on the first node"
    IS_FIRST_NODE=1
else
    echo "Running on consequent (>1st) nodes"
    IS_FIRST_NODE=0
fi

# certificates for easy and automatic deployment
    cat > stack_rsa <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA3y9MOjtzGRl2QIWdaNiAa0v9ANN39DCrRKfOm0cvPYJkwVS0
MMIBQG9ThbN8OcYValWuhRmaBjxQSxU1QWVwexFAomXrjjzWE/j6NqBnKsIiC69n
h8apJgIQokUOoVZ2yiz8RBlaYIkAe9yI/8YAyVSrqs9qqeRl/e0FnE2ouuebBuCq
8akG4pAXZBiisFusFWNa2opX13htLKjBJF8N9agr+WpbFACbfmnKQQ6LDioqCRPD
2xJE5tPWgf8KEdj0XRDCUFQevuaHrYEryQLHH/lVLspOGSznq3q4ofN+mWQiCMPR
q/xYu3gEuyHV5tAl7zaturx1CcoSHz+5lzlmsQIDAQABAoIBAQDeL9wXbO/c4PhU
q7BVnJPcPb4WgHA+7eTTaKvK8kcZWSKtRYJNuBY+65We2Vymt4jCX6JqZ15rLshQ
t0BZZn9gRYCvLAAhjnchUxDmKTIL41C5iVnsVd43NH8SzOUPwWBpTfemZAcRa9LL
fHX3DEvkIyLz3aI2mGbhMIIRZU7BIcy15Xb6zYUgMf9s65EshiR34lbleOLJJKu3
/bfQtnortk+2fdHWYdI31sMt+I+345ukDZ2C/D0+K2c63o+J2WoVCI+JMNGd2j/4
ufwKmkuKhl3IvhV1VGxoq4sGF1Piaz9JfLddjzCaPeNY8DaHFfLHeTCN0prvGv0u
VVBqVk7xAoGBAP+uAzm0K9HH0dOLEqQlalQN4REQ7xCNpB/NgLAwZs5x5qMa4vP5
0b44Y0VsuIcTzMR0bz3EUeY8I+noHOR9QCJtKq91lUMc8CJggrZG2kUfm4s1/8uc
ZrGWDgVd1JRpH116Fi/BxZs6HjdR4PfyjrpzgCp06H8oa5wafJkP2eb3AoGBAN92
3Xxp93CY4wYnvMjxt0DG9drTOnicDqMMOAdalwG3E5cJ41Ofw5JK1wek0BGBWAfu
KWAOxYRPNvE03SFzehb0LE5k6Bfb/Lau2B0AnmpYkHt8KHt5XG+yC2SUvIP576nH
ZlO6wg5ABMrbg6KlTuT84eC1ZA16k0n9OAcevW2XAoGAKgxaJ3FEC5oLHfkvNaOZ
mv01WHMqfdRte3V2hoNPRQBiZ8ySKoGZRulLGi3JIx3UfTKQ4N2agny9g0hTCBi5
JXBCptx1kbX+oAizNnrshpWuJPTafofYM7hz0doejdHEAMGFSJFbiC3ErmBe2Sgg
5PT9zP2xBsiE+gU5HIsI0P0CgYEAob28JA/iy/ms4EikyODDXbxkOMWIXcG+il8O
sqvr/o7PPBQpGN7bRCitKNguzWzMFblY8zDd350iTEWSBGM7rB+BbiB1KMfOSz+U
JrHK93gw42ADQROfRy0cN+m75N5jjIRJ2TKkwIGvtlBaH7/8sZsjtmw0BdmBgB0q
j2S9gPMCgYBb6zmwWy/hXT7G3L06lfshBBL12I1n10Hd7v+i619ByWUxYnO+5HUN
OXdIGgPUen/mxp7SHWgpXDeG7mIeeusD09KtW35CkrfrPI/B/0M5R/Kc4Asnby/v
t+pukxby/5274QAlWHzN2VJ/oCNc6bX/mmBSYFfmi+yQZ6RXG40dXA==
-----END RSA PRIVATE KEY-----
EOF

    cat > stack_rsa.pub <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfL0w6O3MZGXZAhZ1o2IBrS/0A03f0MKtEp86bRy89gmTBVLQwwgFAb1OFs3w5xhVqVa6FGZoGPFBLFTVBZXB7EUCiZeuOPNYT+Po2oGcqwiILr2eHxqkmAhCiRQ6hVnbKLPxEGVpgiQB73Ij/xgDJVKuqz2qp5GX97QWcTai655sG4KrxqQbikBdkGKKwW6wVY1railfXeG0sqMEkXw31qCv5alsUAJt+acpBDosOKioJE8PbEkTm09aB/woR2PRdEMJQVB6+5oetgSvJAscf+VUuyk4ZLOererih836ZZCIIw9Gr/Fi7eAS7IdXm0CXvNq26vHUJyhIfP7mXOWax lorenzo@lorenzo-notebook
EOF

# set permissions
# cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
# chmod 700 /root/.ssh
chmod 644 stack_rsa.pub
chmod 600 stack_rsa

KEY_FILE=$(readlink -m stack_rsa)

# current host
HOST_IP=`LANG=C ifconfig eth0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`
# handle the case when using a wifi connection too
if [ -z "$HOST_IP" ]
then
    HOST_IP=`LANG=C ifconfig wlan0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`
fi

# specific settings for proxy
#PROXY_HOSTS="10.10.242.97 10.10.242.98 10.10.242.99"

# specific settings for storage
#ACCOUNT_HOSTS="10.10.242.6 10.10.242.8"
#CONTAINER_HOSTS="10.10.242.10 10.10.242.46"
#OBJECT_HOSTS="10.10.242.47 10.10.242.48 10.10.242.49 10.10.242.50 10.10.242.53 10.10.242.7 10.10.242.9 10.10.242.51 10.10.242.11 10.10.242.12 10.10.242.52"
# 10.10.242.54

# does the script have to create separate zones ?
# at the moment, a zone is a single group account-container-object
#CREATE_ZONES=0

# include the configuration parameters
source configuration-default.sh

# group all devices for future use
STORAGE_HOSTS=$ACCOUNT_HOSTS" "$CONTAINER_HOSTS" "$OBJECT_HOSTS

#COUNT=( $STORAGE_HOSTS )
#echo ${#COUNT[@]}

# COUNT=( $STORAGE_HOSTS )
# echo ${#COUNT[@]}
# 
# if [ $((${#COUNT[@]}%2)) -eq 0 ]
# then
#     echo "Even number of storage hosts. Please adjust to have couples of 3 nodes (Account, Container, Object)"
#     exit 1
# fi

isRoot

# install dependencies: the policy here is just install; does not matter
# if a package for whatever reason is not used in the end (e.g. option not used)
# ...better safe than sorry!
apt-get update
getPackage python-software-properties
#add-apt-repository ppa:swift-core/release
#apt-get update
#getPackage swift
#getPackage python-swiftclient
getPackage openssh-server
getPackage openssl
getPackage python-pip
getPackage libffi-dev
getPackage python-dev
getPackage rsync

# supported filesystem tools: XFS;F2FS; mainly to provide mkfs.xyz
getPackage xfsprogs
## getPackage f2fs-tools --> deprecated; only available on debian whizzy!?!?!?##
dpkg -i packages/ftp.acc.umu.se/mirror/raspbian/raspbian/pool/main/f/f2fs-tools/libf2fs0_1.6.0-2_armhf.deb
dpkg -i packages/ftp.acc.umu.se/mirror/raspbian/raspbian/pool/main/f/f2fs-tools/f2fs-tools_1.6.0-2_armhf.deb

#apt-get --fix-missing

# Clone and fetch the defined OpenStack Swift(-client) Release

if [ -z $RELEASE ]
then
    # If no release is specified, use the default 2.1.0 on which the system
    # has been developed
    RELEASE="2.1.0"
fi

cd
git clone git://github.com/openstack/python-swiftclient.git
cd ~/python-swiftclient
# hard cleanup and checkout to latest stuff #
git checkout master
git reset --hard origin/master
git pull
git pull origin master
git fetch --tags
git checkout tags/$RELEASE
###
sudo pip install .

cd
git clone git://github.com/openstack/swift.git
cd ~/swift
# hard cleanup and checkout to latest stuff #
git checkout master
git reset --hard origin/master
git pull
git pull origin master
git fetch --tags
git checkout tags/$RELEASE
###
sudo pip install .

## Generic

#install requirements
pip install -r requirements.txt

#apply manual patches
for patch_diff in `ls ../patches/*.diff`
do
    # -p0 indicates that we are interested in absolute paths
    patch -p0 < $patch_diff
done

# add new "swift" user
useradd -p $(openssl passwd password) swift

# setup configuration
mkdir -p /etc/swift
chown -R swift:swift /etc/swift/
mkdir -p /var/log/swift

if [ $IS_FIRST_NODE -eq 1 ]
then

    echo "Generating ring random hash, will be replicated on the other nodes"

    cat >/etc/swift/swift.conf <<EOF
[swift-hash]
# random unique strings that can never change (DO NOT LOSE)
swift_hash_path_prefix = `od -t x8 -N 8 -A n </dev/random`
swift_hash_path_suffix = `od -t x8 -N 8 -A n </dev/random`
EOF

# From 2nd node onwards (basically all nodes except the first) copy the basic configuration

# NOTE: calls are parallelized to make things a lot faster!

for STORAGE_HOST in $STORAGE_HOSTS
do
    if [ "$STORAGE_HOST" != "$HOST_IP" ]
    then
    # NOTE: Folder creation is done in the bulk installer (refer to it)
#        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE root@$STORAGE_HOST "mkdir -p /etc/swift/"
        scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE /etc/swift/swift.conf root@$STORAGE_HOST:/etc/swift/ &
    fi
done

wait # important to wait for completion of scp calls above

for PROXY_HOST in $PROXY_HOSTS
do
    if [ "$PROXY_HOST" != "$HOST_IP" ]
    then
    # NOTE: Folder creation is done in the bulk installer (refer to it)
#        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE root@$PROXY_HOST "mkdir -p /etc/swift/"
        scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE /etc/swift/swift.conf root@$PROXY_HOST:/etc/swift/ &
    fi
done

wait # important to wait for completion of scp calls above

fi

# runtime directories
mkdir -p /var/run/swift
chown swift:swift /var/run/swift 

# storage directories
rm -Rf /var/cache/swift
rm -Rf /srv/node
mkdir -p /var/cache/swift /srv/node/
chown swift:swift /var/cache/swift

getPackage ntp
service ntp restart
service haproxy stop
apt-get remove haproxy

service rsync stop
# sometimes I've seen this file to be a leftover...
# and also dead processes...
killall rsync
rm /var/run/rsyncd.pid

# get deployment variables if set, otherwise use default values
if [ -z $PROXY_WORKERS ]
then
    PROXY_WORKERS="1"
fi

case "$NODE_TYPE" in

    "$NODE_TYPE_PROXY" )
        echo "Installing a proxy node"

        echo "Quitting running instances..."
        # Cleanup any running instance, if any
        swift-init proxy stop
        service memcached stop

        # SSL testing support
        getPackage memcached #swift-proxy
        cd /etc/swift

        # This step is needed if SSL is turned on.
        # At the moment, also because of benchmarking, we simply keep it off
        if [ "$SSL_ENABLED" == "yes" ]
        then
            openssl req -new -x509 -nodes -out cert.crt -keyout cert.key
        fi

        # memcached listening
        # NOTE problems in starting memcached means authorization errors (curl, client...)
        perl -pi -e "s/-l 127.0.0.1/-l $HOST_IP/" /etc/memcached.conf
        service memcached restart

        # create the configuration for the proxy server
        cat >/etc/swift/proxy-server.conf <<EOF
        
[DEFAULT]
swift_dir = /etc/swift
bind_ip = 0.0.0.0
bind_port = 8080
bind_timeout = 30
# pre-forked processes. No more than 1 on the Raspberry ...
workers = 1
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
memcache_servers = `join_port , 11211 $PROXY_HOSTS`
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
service_host = $HOST_IP
service_port = 5000
auth_host = $HOST_IP
auth_port = 35357
auth_protocol = http
auth_uri = http://$HOST_IP:5000/
admin_tenant_name = service
admin_user = swift
admin_password = swift
delay_auth_decision = 0

EOF

# If we are setting up another proxy node, we don't have to redo all the balancing
if [ $IS_FIRST_NODE -eq 1 ]
then

    # create the account, container and object rings
    cd /etc/swift
    rm -f account.builder account.ring.gz backups/account.builder backups/account.ring.gz
    rm -f container.builder container.ring.gz backups/container.builder container.ring.gz
    rm -f object.builder object.ring.gz backups/object.builder backups/object.ring.gz
    rm -f *.builder *.ring.gz backups/*.builder backups/*.ring.gz

    swift-ring-builder account.builder create $PARTITIONS $REPLICATION 1
    swift-ring-builder container.builder create $PARTITIONS $REPLICATION 1
    swift-ring-builder object.builder create $PARTITIONS $REPLICATION 1

    # setting up zones. Basically this has to be done for every storage node, zone
    # increments by 1 everytime

    ZONE=1
    WEIGHT=100.0               # relative weight (higher for bigger/faster disks)
    DEVICE=sdb1

    for i in $ACCOUNT_HOSTS
    do
        swift-ring-builder account.builder add z$ZONE-$i:6002/$DEVICE $WEIGHT
        if [ $CREATE_ZONES -eq 1 ]
        then
            ZONE=$(($ZONE+1))
        fi
    done

    ZONE=1
    for i in $CONTAINER_HOSTS
    do
        swift-ring-builder container.builder add z$ZONE-$i:6001/$DEVICE $WEIGHT
        if [ $CREATE_ZONES -eq 1 ]
        then
            ZONE=$(($ZONE+1))
        fi
    done

    ZONE=1
    for i in $OBJECT_HOSTS
    do
        swift-ring-builder object.builder add z$ZONE-$i:6000/$DEVICE $WEIGHT
        if [ $CREATE_ZONES -eq 1 ]
        then
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
    sleep 5
    ls /etc/swift
    for STORAGE_HOST in $STORAGE_HOSTS
    do
        if [ "$STORAGE_HOST" != "$HOST_IP" ]
        then
            scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE /etc/swift/*.ring.gz root@$STORAGE_HOST:/etc/swift &
        fi
    done

    wait # important to wait for completion of scp calls above

    for PROXY_HOST in $PROXY_HOSTS
    do
        if [ "$PROXY_HOST" != "$HOST_IP" ]
        then
            scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $KEY_FILE /etc/swift/*.ring.gz root@$PROXY_HOST:/etc/swift &
        fi
    done

    wait # important to wait for completion of scp calls above

fi

    # Copy the account.ring.gz, container.ring.gz, and object.ring.gz files to each of the Proxy and Storage nodes in /etc/swift.

    chown -R swift:swift /etc/swift

    swift-init proxy restart

    ;;

    "$NODE_TYPE_STORAGE" )
        echo "Installing a storage node"

        echo "Quitting running instances..."

        # Stop object server instance(s)
        swift-init object-server stop
        swift-init object-replicator stop
        swift-init object-updater stop
        swift-init object-auditor stop
        
        # Stop container server instance(s)
        swift-init container-server stop
        swift-init container-replicator stop
        swift-init container-updater stop
        swift-init container-auditor stop
        swift-init container-info stop
        swift-init container-sync stop
        swift-init container-reconciler stop

        # Stop account server instance(s)
        swift-init account-server stop
        swift-init account-replicator stop
        swift-init account-updater stop
        swift-init account-auditor stop
        
        swift-init proxy stop

        # For every device on the node, setup the XFS volume (/dev/sdb is used as an example), add mounting option inode64 when your disk is bigger than 1TB to archive a better performance.

        # Check if a specific filesystem has been chosen. defaults to "XFS"

        if [ -z $FILESYSTEM ]
        then
            # If no filesystem is specified, default it to "XFS"
            FILESYSTEM="XFS"
        fi

        STORAGE_DISK="/swift-storage"
        ## cleanup and basic setup (filesystem generic)
        umount /srv/node/sdb1
        umount -f -l /srv/node/sdb1 # force and lazy umount if everything fails -> gives a chance to build fresh FS anyway
        rm -f $STORAGE_DISK
        # cleanup of eventual objects that went in the ROOTFS tree
        rm -R -f /srv/node/sdb1

        # remove the (potentially existing) filesystem entry
        cp /etc/fstab /etc/fstab.backup
        sed '/^\/swift-storage/d' /etc/fstab > /etc/fstab.new
        cp /etc/fstab.new /etc/fstab

        # allocate filesystem image space (filesystem generic)
        truncate -s 1024M $STORAGE_DISK
        
        # prepare mount point
        mkdir -p /srv/node/sdb1

        ## end of basic setup (filesystem generic)

        case "$FILESYSTEM" in

            "XFS" )
                echo "XFS Filesystem has been selected"
                # create and format filesystem
                mkfs.xfs -i size=1024 $STORAGE_DISK
                # add fstab entry for the specific filesystem
                echo "$STORAGE_DISK /srv/node/sdb1 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
            ;;

            "F2FS" )
                echo "F2FS Filesystem has been selected"
                # create and format filesystem
                mkfs.f2fs $STORAGE_DISK
                # add fstab entry for the specific filesystem
                echo "$STORAGE_DISK /srv/node/sdb1 f2fs loop,noatime,nodiratime 0 0" >> /etc/fstab
            ;;
            
            "EXT4" )
                echo "EXT4 Filesystem has been selected"
                echo "STUB! ABORTING!"
                exit 1
            ;;
            
            "ROOTFS" )
                echo "ROOTFS Filesystem has been selected"
                echo "STUB! ABORTING!"
                exit 1
            ;;

            * )
                echo "Unknown filesystem selected -$FILESYSTEM- [ XFS | F2FS | EXT4 | ROOTFS ]. Aborting."
                exit 1
            ;;

        esac

        # mount the freshly created filesystem
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
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/account.lock

[container]
max connections = 4
path = /srv/node/
read only = false
lock file = /var/lock/container.lock

[object]
max connections = 8
path = /srv/node/
read only = false
lock file = /var/lock/object.lock
EOF

    # Edit the RSYNC_ENABLE= line in /etc/default/rsync:

    perl -pi -e 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync

    # Start rsync daemon:

    service rsync restart

    # Create /etc/swift/account-server.conf:

    cat >/etc/swift/account-server.conf <<EOF
[DEFAULT]
swift_dir = /etc/swift
devices = /srv/node
user = swift
bind_ip = $HOST_IP
bind_port = 6002
workers = 1
db_preallocation = off

[pipeline:main]
pipeline = account-server

[app:account-server]
use = egg:swift#account

[account-replicator]

[account-auditor]
accounts_per_second = 100

[account-reaper]
EOF

    # Create /etc/swift/container-server.conf:

    cat >/etc/swift/container-server.conf <<EOF
[DEFAULT]
swift_dir = /etc/swift
devices = /srv/node
user = swift
bind_ip = $HOST_IP
bind_port = 6001
workers = 1
db_preallocation = off

[pipeline:main]
pipeline = container-server

[app:container-server]
use = egg:swift#container

[container-replicator]

[container-updater]

[container-auditor]
containers_per_second = 100

[container-sync]
EOF

    # Create /etc/swift/object-server.conf:

    cat >/etc/swift/object-server.conf <<EOF
[DEFAULT]
swift_dir = /etc/swift
devices = /srv/node
user = swift
bind_ip = $HOST_IP
bind_port = 6000
workers = 1
db_preallocation = off
mount_check = false

[pipeline:main]
pipeline = object-server

[app:object-server]
use = egg:swift#object

[object-replicator]

[object-updater]

[object-auditor]
files_per_second = 50
bytes_per_second = 1000000
EOF

    #Start the storage services. If you use this command, it will try to start every service for which a configuration file exists, and throw a warning for any configuration files which don’t exist:

#     COUNT=( $STORAGE_HOSTS )
#     echo ${#COUNT[@]}
# 
#     for i in $(eval echo "{0..$((${#COUNT[@]}/3-1))}")
#     do
#         if [ "$HOST_IP" == "${COUNT[$(($i+2))]}" ]
#         then
#             swift-init object-server restart
#             swift-init object-replicator restart
#             swift-init object-updater restart
#             swift-init object-auditor restart
#         fi
# 
#         if [ "$HOST_IP" == "${COUNT[$(($i+1))]}" ]
#         then
#             swift-init container-server restart
#             swift-init container-replicator restart
#             swift-init container-updater restart
#             swift-init container-auditor restart
#         fi
# 
#         if [ "$HOST_IP" == "${COUNT[$(($i+0))]}" ]
#         then
#             swift-init account-server restart
#             swift-init account-replicator restart
#             swift-init account-auditor restart
#         fi
# 
#     done


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

    for i in $ACCOUNT_HOSTS
    do
        if [ "$HOST_IP" == "$i" ]
        then
            swift-init account-server restart
            swift-init account-replicator restart
            swift-init account-updater restart
            swift-init account-auditor restart
        fi
    done

    for i in $CONTAINER_HOSTS
    do
        if [ "$HOST_IP" == "$i" ]
        then
            swift-init container-server restart
            swift-init container-replicator restart
            swift-init container-updater restart
            swift-init container-auditor restart
            swift-init container-info restart
            swift-init container-sync restart
            swift-init container-reconciler restart
        fi
    done

    for i in $OBJECT_HOSTS
    do
        if [ "$HOST_IP" == "$i" ]
        then
            swift-init object-server restart
            swift-init object-replicator restart
            swift-init object-updater restart
            swift-init object-auditor restart
        fi
    done

    # Note: this is a workaround for deployment on a single (or localhost) machine
    # Proxy server gets stopped in the previous step, so here it is time to
    # turn it on again
    if [ "$MASTER_PROXY" == "$HOST_IP" ]
    then
        swift-init proxy restart
    fi
#Or, if you want to start them one at a time, run them as below. Note that if the server program in question generates any output on its stdout or stderr, swift-init has already redirected the command’s output to /dev/null. If you encounter any difficulty, stop the server and run it by hand from the command line. Any server may be started using “swift-$SERVER-$SERVICE /etc/swift/$SERVER-config”, where $SERVER might be object, continer, or account, and $SERVICE might be server, replicator, updater, or auditor.

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


        
    ;;

    * )
        echo "Unknown installation type [ proxy | storage ]. Aborting."
        exit 1
    ;;

esac

echo "All done. Bye!"
