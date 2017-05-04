#!/bin/bash

# Example 1
# Create container (if not exists)

# Project: Thesis !
# Lorenzo Miori (C) 2014
#
# Modified by Julian Sanin (2017)
#

set -u
source "$(dirname $0)/examples_configuration.sh"

if [ "$#" -ne 1 ]; then
  cat << EOF
Usage: $0 container_name
EOF
  exit 0
fi

readonly CONTAINER="$1"
readonly OBJECT_NAME="an_object_for_lorenzo"

function header_get_by_name() {
    echo "$1" | tr -d '\r' | sed -En 's/^'$2': (.*)/\1/p'
}

# Get the authentication token
readonly AUTHENTICATION=$(curl -s -i -H "X-Auth-User: $USER_AUTHENTICATION" -H "X-Auth-Key: $KEY_AUTHENTICATION" $URL_AUTHENTICATION)

readonly XSTORAGEURL=`header_get_by_name "$AUTHENTICATION" X-Storage-Url`
readonly XAUTHTOKEN=`header_get_by_name "$AUTHENTICATION" X-Auth-Token`

# Create a container for objects
echo "Creating container: $CONTAINER"
echo "  Using X-Auth-Token: $XAUTHTOKEN"
echo "  Executing: PUT $XSTORAGEURL/$CONTAINER"
echo "    "$(curl -si -H "X-Auth-Token: $XAUTHTOKEN" -X PUT $XSTORAGEURL/$CONTAINER | head -n 1)
exit 0
