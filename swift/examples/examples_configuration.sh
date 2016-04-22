#!/bin/bash

# Get the proxy address for running the examples
cd $(dirname $0)/..
source configuration-default.sh

# Authentication URL
URL_AUTHENTICATION="http://$LOAD_BALANCER:8080/auth/v1.0/"

# Authentication user
USER_AUTHENTICATION="system:root"

# Authentication key
KEY_AUTHENTICATION="testpass"
