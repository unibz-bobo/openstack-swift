#!/bin/bash

# Example 2
# Store an object

# Project: Thesis !
# Lorenzo Miori (C) 2014
#
# Modified by Julian Sanin (2017)
#

set -u
source "$(dirname $0)/examples_configuration.sh"

if [ "$#" -ne 2 ]; then
  cat << EOF
Usage: $0 container_name/object_name object_value
EOF
  exit 0
fi

readonly CONTAINER_OBJECT="$1"
readonly OBJECT_VALUE="$2"

function header_get_by_name() {
    echo "$1" | tr -d '\r' | sed -En 's/^'$2': (.*)/\1/p'
}

# Get the authentication token
readonly AUTHENTICATION=$(curl -s -i -H "X-Auth-User: $USER_AUTHENTICATION" -H "X-Auth-Key: $KEY_AUTHENTICATION" $URL_AUTHENTICATION)

readonly XSTORAGEURL=`header_get_by_name "$AUTHENTICATION" X-Storage-Url`
readonly XAUTHTOKEN=`header_get_by_name "$AUTHENTICATION" X-Auth-Token`

# Put an object
echo "Creating object: $CONTAINER_OBJECT"
echo "  Using X-Auth-Token: $XAUTHTOKEN"
echo "  Content-Length: ${#OBJECT_VALUE}"
echo "  Data: $OBJECT_VALUE"
echo "  PUT $XSTORAGEURL/$CONTAINER_OBJECT"
echo "    "`curl -si -H "X-Auth-Token: $XAUTHTOKEN" -H "Content-Length: ${#OBJECT_VALUE}" --data "$OBJECT_VALUE" -X PUT $XSTORAGEURL/$CONTAINER_OBJECT | head -n 1`
exit 0
