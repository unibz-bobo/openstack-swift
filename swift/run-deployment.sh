#!/bin/bash

# This script will run the necessary steps to deploy Swift on the cluster

LOGS="logs"
LOG_FILENAME="deployment.log"

mkdir -p $LOGS

set +x

./update-script.sh > $LOGS/$LOG_FILENAME.log 2>&1
./install-proxy-bulk.sh >> $LOGS/$LOG_FILENAME.log 2>&1
./install-storage-bulk.sh >> $LOGS/$LOG_FILENAME.log 2>&1
./install-load-balancer.sh >> $LOGS/$LOG_FILENAME.log 2>&1

echo "    - running first test"
examples/store_and_retrieve_character.sh >> $LOGS/$LOG_FILENAME.log 2>&1
examples/store_and_retrieve_character.sh >> $LOGS/$LOG_FILENAME.log 2>&1

echo "Done! You can find logs in the $LOGS folder."
