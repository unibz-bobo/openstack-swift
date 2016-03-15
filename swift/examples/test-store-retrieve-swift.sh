#!/bin/bash

# Example 1
# Create container (if not exists)
# Store a character
# Get it back

# Project: Thesis !
# Lorenzo Miori (C) 2014

set -x

source $(dirname $0)/examples_configuration.sh

CONTAINER="gogreenhouse"
OBJECT_NAME="raw/rfm69/8686/43/13290i81249/temp"

function header_get_by_name() {
    echo "$1" | tr -d '\r' | sed -En 's/^'$2': (.*)/\1/p'
}

# Get the authentication token
AUTHENTICATION=$(curl -s -i -H "X-Auth-User: $USER_AUTHENTICATION" -H "X-Auth-Key: $KEY_AUTHENTICATION" $URL_AUTHENTICATION)

XSTORAGEURL=`header_get_by_name "$AUTHENTICATION" X-Storage-Url`
XAUTHTOKEN=`header_get_by_name "$AUTHENTICATION" X-Auth-Token`
echo "$XSTORAGEURL"
echo "$XAUTHTOKEN"

# Create a container for objects
curl -H "X-Auth-Token: $XAUTHTOKEN" -X PUT $XSTORAGEURL/$CONTAINER

# Put a single character
curl -H "X-Auth-Token: $XAUTHTOKEN" -H "Content-Length: 2" --data "27" -X PUT $XSTORAGEURL/$CONTAINER/$OBJECT_NAME

# Get back your data (finally :) )

res=`curl -H "X-Auth-Token: $XAUTHTOKEN" -X GET $XSTORAGEURL/$CONTAINER/$OBJECT_NAME`
echo "$res"
