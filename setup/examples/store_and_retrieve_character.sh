#!/bin/bash

# Example 1
# Create container (if not exists)
# Store a character
# Get it back

# Project: Thesis !
# Lorenzo Miori (C) 2014
#
# Modified by Julian Sanin (2016)
#

set -u
source "$(dirname $0)/examples_configuration.sh"

readonly CONTAINER="lorenzo"
readonly OBJECT_NAME="an_object_for_lorenzo"

function header_get_by_name() {
    echo "$1" | tr -d '\r' | sed -En 's/^'$2': (.*)/\1/p'
}

# Get the authentication token
readonly AUTHENTICATION=$(curl -s -i -H "X-Auth-User: $USER_AUTHENTICATION" -H "X-Auth-Key: $KEY_AUTHENTICATION" $URL_AUTHENTICATION)

readonly XSTORAGEURL=`header_get_by_name "$AUTHENTICATION" X-Storage-Url`
readonly XAUTHTOKEN=`header_get_by_name "$AUTHENTICATION" X-Auth-Token`

# Create a container for objects
echo "Creating container: 'X-Auth-Token: $XAUTHTOKEN' PUT $XSTORAGEURL/$CONTAINER"
curl -H "X-Auth-Token: $XAUTHTOKEN" -X PUT $XSTORAGEURL/$CONTAINER
echo ""
# Put a single character
echo "Writing character 'C': 'X-Auth-Token: $XAUTHTOKEN' PUT $XSTORAGEURL/$CONTAINER/$OBJECT_NAME"
curl -H "X-Auth-Token: $XAUTHTOKEN" -H "Content-Length: 1" --data "C" -X PUT $XSTORAGEURL/$CONTAINER/$OBJECT_NAME
echo ""
# Get back your data (finally :) )
echo "Reading character 'C': 'X-Auth-Token: $XAUTHTOKEN' GET $XSTORAGEURL/$CONTAINER/$OBJECT_NAME"
curl -H "X-Auth-Token: $XAUTHTOKEN" -X GET $XSTORAGEURL/$CONTAINER/$OBJECT_NAME
echo ""
