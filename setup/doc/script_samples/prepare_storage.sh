#!/bin/bash

function log_print_phase() {
    echo "#######################################"
    echo "$1"
    echo "#######################################"
}

log_print_phase "Installing partitions ..."

# build loopback drive
sudo mkdir -p /srv
sudo truncate -s 1GB /srv/swift-disk
sudo mkfs.xfs -f -i size=512 /srv/swift-disk

# update /etc/fstab
grep '/srv/swift-disk' /etc/fstab
if [ $? = 1 ]; then
sudo tee -a /etc/fstab >/dev/null <<EOF

/srv/swift-disk /mnt/sdb1 xfs loop,noatime,nodiratime,nobarrier,inode64,logbufs=8 0 0
EOF
fi

sudo mkdir -p /mnt/sdb1/1

sudo chown -R pi:pi /mnt/sdb1/1
sudo ln -fs /mnt/sdb1/1 /srv/1
#sudo chown -R pi:pi /etc/swift /srv/1/ /var/run/swift

log_print_phase "Done installing partitions"
