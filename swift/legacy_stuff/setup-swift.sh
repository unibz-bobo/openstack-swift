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

# WARNING
# Multiple nodes are yet untested and indeed there are some bugs in the script yet to be fixed
# WARNING

# current host
HOST_IP=`LANG=C ifconfig eth0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`
# handle the case when using a wifi connection too
if [ -z "$HOST_IP" ]
then
    HOST_IP=`LANG=C ifconfig wlan0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`
fi

# specific settings for storage
STORAGE_HOSTS="10.10.242.6 10.10.242.7 10.10.242.8 10.10.242.9"

# specific settings for proxy
PROXY_HOSTS="10.10.242.99"

isRoot

# install dependencies
#apt-get update
getPackage python-software-properties
#add-apt-repository ppa:swift-core/release
#apt-get update
#getPackage swift
#getPackage python-swiftclient
getPackage openssh-server
getPackage openssl

#set +e
cd && git clone git://github.com/openstack/python-swiftclient.git
#set -e
cd ~/python-swiftclient; git pull origin master && sudo pip install .

#set +e
cd && git clone git://github.com/openstack/swift.git
#set -e
cd ~/swift; git pull origin master && sudo pip install .

## Generic

# add new "swift" user
useradd -p $(openssl passwd password) swift

# setup configuration
mkdir -p /etc/swift
chown -R swift:swift /etc/swift/

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
for STORAGE_HOST in $STORAGE_HOSTS
do
    if [ "$STORAGE_HOST" != "$HOST_IP" ]
    then
        scp root@$STORAGE_HOST:/etc/swift/swift.conf /etc/swift
    fi
done
for PROXY_HOST in $PROXY_HOSTS
do
    if [ "$PROXY_HOST" != "$HOST_IP" ]
    then
        scp root@$PROXY_HOST:/etc/swift/swift.conf /etc/swift
    fi
done

fi

# runtime directories
mkdir -p /var/run/swift
chown swift:swift /var/run/swift 

# storage directories
mkdir -p /var/cache/swift /srv/node/
chown swift:swift /var/cache/swift

case "$NODE_TYPE" in

    "$NODE_TYPE_PROXY" )
        echo "Installing a proxy node"

        echo "Quitting running instances..."
        # Cleanup any running instance, if any
        swift-init proxy stop

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
#bind_ip = 10.10.242.99
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
pipeline = healthcheck proxy-logging cache tempauth proxy-logging proxy-server

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

[filter:proxy-logging]
use = egg:swift#proxy_logging

[filter:tempauth]
use = egg:swift#tempauth
# The reseller prefix will verify a token begins with this prefix before even
# attempting to validate it. Also, with authorization, only Swift storage
# accounts with this prefix will be authorized by this middleware. Useful if
# multiple auth systems are in use for one Swift cluster.
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
memcache_servers = $HOST_IP:11211
set log_name = cache

[filter:swiftauth]
paste.filter_factory = keystone.middleware.swift_auth:filter_factory
operator_roles = admin, swiftoperator
is_admin = true

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
admin_password = hastexo
delay_auth_decision = 0

EOF

    # create the account, container and object rings
    cd /etc/swift
    rm -f account.builder account.ring.gz backups/account.builder backups/account.ring.gz
    rm -f container.builder container.builder backups/container.builder container.ring.gz
    rm -f object.builder account.ring.gz backups/object.builder backups/account.ring.gz
    swift-ring-builder account.builder create 7 3 1
    swift-ring-builder container.builder create 7 3 1
    swift-ring-builder object.builder create 7 3 1

    # setting up zones. Basically this has to be done for every storage node, zone
    # increments by 1 everytime

    ZONE=1
    for STORAGE_HOST in $STORAGE_HOSTS
    do
        STORAGE_LOCAL_NET_IP=$STORAGE_HOST    # and the IP address
        WEIGHT=1               # relative weight (higher for bigger/faster disks)
        DEVICE=sdb1
        swift-ring-builder account.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6002/$DEVICE $WEIGHT
        swift-ring-builder container.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6001/$DEVICE $WEIGHT
        swift-ring-builder object.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6000/$DEVICE $WEIGHT
        # increment zone counter
        ZONE=$(($ZONE+1))                    # set the zone number for that storage device
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
    for STORAGE_HOST in $STORAGE_HOSTS
    do
        if [ "$STORAGE_HOST" != "$HOST_IP" ]
        then
            scp root@$STORAGE_HOST:/etc/swift/account.ring.gz /etc/swift
            scp root@$STORAGE_HOST:/etc/swift/container.ring.gz /etc/swift
            scp root@$STORAGE_HOST:/etc/swift/object.ring.gz /etc/swift
        fi
    done
    for PROXY_HOST in $PROXY_HOSTS
    do
        if [ "$PROXY_HOST" != "$HOST_IP" ]
        then
            scp root@$PROXY_HOST:/etc/swift/account.ring.gz /etc/swift
            scp root@$PROXY_HOST:/etc/swift/container.ring.gz /etc/swift
            scp root@$PROXY_HOST:/etc/swift/object.ring.gz /etc/swift
        fi
    done


    # Copy the account.ring.gz, container.ring.gz, and object.ring.gz files to each of the Proxy and Storage nodes in /etc/swift.

    chown -R swift:swift /etc/swift

    swift-init proxy restart

    ;;

    "$NODE_TYPE_STORAGE" )
        echo "Installing a storage node"

        echo "Quitting running instances..."
        swift-init object-server stop
        swift-init object-replicator stop
        swift-init object-updater stop
        swift-init object-auditor stop
        swift-init container-server stop
        swift-init container-replicator stop
        swift-init container-updater stop
        swift-init container-auditor stop
        swift-init account-server stop
        swift-init account-replicator stop
        swift-init account-auditor stop

        # For every device on the node, setup the XFS volume (/dev/sdb is used as an example), add mounting option inode64 when your disk is bigger than 1TB to archive a better performance.

        STORAGE_DISK="/swift-storage"
        ## cleanup if needed
        umount /srv/node/sdb1
        rm -f $STORAGE_DISK
        ##
        truncate -s 512M $STORAGE_DISK
        mkfs.xfs -i size=512 $STORAGE_DISK
        grep '$STORAGE_DISK' /etc/fstab
        if [ $? = 1 ]
        then
            echo "$STORAGE_DISK /srv/node/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
        fi
        mkdir -p /srv/node/sdb1
        mount /srv/node/sdb1
        chown swift:swift /srv/node/sdb1

        # Create /etc/rsyncd.conf:

        cat >/etc/rsyncd.conf <<EOF
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = $HOST_IP

[account]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/object.lock
EOF

    # Edit the RSYNC_ENABLE= line in /etc/default/rsync:

    perl -pi -e 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync

    # Start rsync daemon:

    service rsync start

    # Create /etc/swift/account-server.conf:

    cat >/etc/swift/account-server.conf <<EOF
[DEFAULT]
bind_ip = $HOST_IP
workers = 2

[pipeline:main]
pipeline = account-server

[app:account-server]
use = egg:swift#account

[account-replicator]

[account-auditor]

[account-reaper]
EOF

    # Create /etc/swift/container-server.conf:

    cat >/etc/swift/container-server.conf <<EOF
[DEFAULT]
bind_ip = $HOST_IP
workers = 2

[pipeline:main]
pipeline = container-server

[app:container-server]
use = egg:swift#container

[container-replicator]

[container-updater]

[container-auditor]

[container-sync]
EOF

    # Create /etc/swift/object-server.conf:

    cat >/etc/swift/object-server.conf <<EOF
[DEFAULT]
bind_ip = $HOST_IP
workers = 2

[pipeline:main]
pipeline = object-server

[app:object-server]
use = egg:swift#object

[object-replicator]

[object-updater]

[object-auditor]
EOF

    #Start the storage services. If you use this command, it will try to start every service for which a configuration file exists, and throw a warning for any configuration files which don’t exist:

#    swift-init all start
    swift-init object-server restart
    swift-init object-replicator restart
    swift-init object-updater restart
    swift-init object-auditor restart
    swift-init container-server restart
    swift-init container-replicator restart
    swift-init container-updater restart
    swift-init container-auditor restart
    swift-init account-server restart
    swift-init account-replicator restart
    swift-init account-auditor restart

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
