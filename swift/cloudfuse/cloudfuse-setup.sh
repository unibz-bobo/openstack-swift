#!/bin/bash

isRoot() {
  if [ `whoami` != "root" ]; then
    echo "Please run '$0' as root or execute it with sudo!"
    exit -1
  fi
}

#!/bin/bash

isRoot

function GROUPID {
    if [ $# -ne 0 ]
    then
        GRPID=$1
        grep "^$GRPID" /etc/group|cut -d: -f3
    else
        echo USAGE="Usage: grp_id <group name> "
    fi
}

which cloudfuse
if [ $? -ne 0 ]
then
    echo "Installing cloudfuse"
    echo "  - dependencies"
    sudo apt-get install -y build-essential libcurl4-openssl-dev libxml2-dev libssl-dev libfuse-dev > /dev/null
    echo "  - cloning the repo"
    git clone https://github.com/redbo/cloudfuse.git
    cd cloudfuse
    echo "  - updating the repo"
    git pull
    echo "  - building"
    ./configure
    make
    sudo make install
    echo "done!"
else
    echo "Warning: cloudfuse is already installed"
fi

echo "Installing configuration"
cat > /root/.cloudfuse <<EOF
username=system:root
api_key=testpass
password=testpass
authurl=http://10.10.242.55:8080/auth/v1.0/
cache_timeout=60
EOF

echo "Preliminary cleanup"
sync
umount /media/cloudfiles

# important to set the correct permissions
chmod 600 /root/.cloudfuse

# create directory and set permissions
mkdir -p /media/cloudfiles
# we want the web server to be in the fuse group too
usermod -a -G fuse www-data

# WTF! fstab method does not work under Raspbian ?!?!?!?!

# grep '/media/cloudfiles' /etc/fstab
# if [ $? = 1 ]
# then
#     FUSEGROUP=$(GROUPID fuse)
#     echo "cloudfuse       /media/cloudfiles       fuse    defaults,gid=$FUSEGROUP,umask=007,allow_other  0 0" >> /etc/fstab
# fi

# a working alternative

grep 'cloudfuse' /etc/crontab
if [ $? = 1 ]
then
    echo "@reboot root modprobe fuse" >> /etc/crontab
    echo "@reboot root cloudfuse /media/cloudfiles -o allow_other,nonempty" >> /etc/crontab
fi

# finally mount the device!
cloudfuse /media/cloudfiles -o allow_other,nonempty
