#!/bin/bash

set -x

isRoot() {
  if [ `whoami` != "root" ]; then
    echo "Please run '$0' as root or execute it with sudo!"
    exit -1
  fi
}

isRoot

apt-get install -y python-dev python-pip 'g++' libzmq-dev libevent-dev
pip install --upgrade distribute
pip install Cython gevent pyzmq==2.2.0
pip install ssbench --allow-external statlib --allow-unverified statlib
