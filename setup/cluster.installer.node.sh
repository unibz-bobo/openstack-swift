#!/bin/bash

# (C) 2014 Lorenzo Miori
#   Bachelor Thesis Project: middleware deployment and evaluation of a Raspb$
#
# Modified by Julian Sanin (2016)
#

# This script will install OpenStack Swift on each cluster node.

set -u
#set -x

source "$(dirname $0)/swman/swman.lib.sh"
source "$(dirname $0)/cluster.lib.sh"
source "$(dirname $0)/cluster.cfg.sh"

clusterInit "$CLUSTER_CONFIGURATION" 1

echo "===================================="
echo "Starting something big..."
echo "In the meantime enjoy a moment of wisdom"
echo "Never - ever - rely on default values if they are valuable and critical"
echo "Trust me, not as engineer, nor as expert, but as poor's man debug advisor"
echo "===================================="

# Set permissions.
chmod 644 stack_rsa.pub
chmod 600 stack_rsa

clusterIsRoot "$0"

# install dependencies: the policy here is just install; does not matter
# if a package for whatever reason is not used in the end (e.g. option not used)
# ...better safe than sorry!

# Generic OS packages
packageUpdate
clusterGetPackage openssl
clusterGetPackage rsync
# supported filesystem tools: XFS;F2FS; mainly to provide mkfs.xyz
clusterGetPackage xfsprogs
clusterGetPackage f2fs-tools
clusterGetPackage git
clusterGetPackage ntp
clusterGetPackage memcached # Needed for swift-proxy.

# Specific OS package setup
if [ "$ID_LIKE" = debian ]; then
  #clusterGetPackage python-software-properties # Only needed when ppa is used.
  ##add-apt-repository ppa:swift-core/release
  ##apt-get update
  ##clusterGetPackage swift
  ##clusterGetPackage python-swiftclient
  clusterGetPackage python-pip
  clusterGetPackage libffi-dev
  clusterGetPackage python-dev
  clusterGetPackage build-essential
  if [ "$ID" = raspbian ]; then
    if [[ "$VERSION" == *wheezy* ]]; then
      ## clusterGetPackage f2fs-tools --> deprecated; not available on raspbian wheezy!?!?!?##
      dpkg -i packages/ftp.acc.umu.se/mirror/raspbian/raspbian/pool/main/f/f2fs-tools/libf2fs0_1.6.0-2_armhf.deb
      dpkg -i packages/ftp.acc.umu.se/mirror/raspbian/raspbian/pool/main/f/f2fs-tools/f2fs-tools_1.6.0-2_armhf.deb
    fi
  fi
  serviceRestart ntp
  serviceStop rsync
  #apt-get --fix-missing
elif [ "$ID_LIKE" = arch ]; then
  clusterGetPackage python2-pip
  clusterGetPackage libffi
  pacman -S --noconfirm --needed base-devel
  serviceStop ntpd
  serviceStart ntpd
  serviceStop rsyncd
  # Workaround. See also cluster.installer.proxy.sh
  serviceStop swift-memcached
else
  echo "Node installer stub. Please implement script '$0' for OS '$ID_LIKE'."
  exit -1
fi

# OS generic cleanup
serviceStop haproxy
packageUninstall haproxy
serviceStop memcached

# sometimes I've seen this file to be a leftover...
# and also dead processes...
killall rsync
rm /var/run/rsyncd.pid

# Clone and fetch the defined OpenStack Swift(-client) Release
if [ -z $CLUSTER_SWIFT_CLIENT_RELEASE ]; then
    # If no release is specified, use the default 2.1.0 on which the system
    # has been developed
    RELEASE="2.1.0"
else
    RELEASE="$CLUSTER_SWIFT_CLIENT_RELEASE"
fi
cd
git clone git://github.com/openstack/python-swiftclient.git
cd python-swiftclient
# hard cleanup and checkout to latest stuff #
git checkout master
git reset --hard origin/master
git pull
git pull origin master
git fetch --tags
git checkout tags/$RELEASE
###
if [[ "$ID_LIKE" = debian && "$VERSION" == *wheezy* ]]; then
  pip install .
else
  pip2 install .
fi

if [ "$ID_LIKE" = arch ]; then
  packageQuery liberasurecode
  if [ "$?" != 0 ]; then
    # Install dependency for PyECLib.
    cd
    git clone https://aur.archlinux.org/liberasurecode.git
    cd liberasurecode
    # Hacky workaround to let makepkg build something with the root user.
    chown -R nobody:nobody .
    echo 'nobody ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/makepkg-liberasurecode
    sudo -u nobody makepkg -sir --noconfirm
    rm /etc/sudoers.d/makepkg-liberasurecode
    chown -R root:root .
    # Who had the great idea to remove --asroot from makepkg?
  fi
fi

# Clone and fetch the defined OpenStack Swift(-client) Release
if [ -z $CLUSTER_SWIFT_RELEASE ]; then
    # If no release is specified, use the default 2.1.0 on which the system
    # has been developed
    RELEASE="2.1.0"
else
    RELEASE="$CLUSTER_SWIFT_RELEASE"
fi
cd
git clone git://github.com/openstack/swift.git
cd swift
# hard cleanup and checkout to latest stuff #
git checkout master
git reset --hard origin/master
git pull
git pull origin master
git fetch --tags
git checkout tags/$RELEASE
###
if [[ "$ID_LIKE" = debian && "$VERSION" == *wheezy* ]]; then
  pip install .
  #install requirements
  pip install -r requirements.txt 
else
  pip2 install .
  #install requirements
  pip2 install -r requirements.txt
fi

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

# runtime directories
mkdir -p /var/run/swift
chown swift:swift /var/run/swift

# storage cleanup basic setup (filesystem generic)
umount /srv/node/sdb1
umount -f -l /srv/node/sdb1 # force and lazy umount if everything fails -> gives a chance to build fresh FS anyway
# cleanup of eventual objects that went in the ROOTFS tree
rm -R -f /srv/node/sdb1
# remove the (potentially existing) filesystem entry
sed -i.bak "\@/srv/node/sdb1@d" /etc/fstab

# storage directories
rm -Rf /var/cache/swift
rm -Rf /srv/node
mkdir -p /var/cache/swift /srv/node/
chown swift:swift /var/cache/swift

exit 0
