#!/bin/bash

# (C) 2014 Lorenzo Miori
#   Bachelor Thesis Project: middleware deployment and evaluation of a Raspberry Cluster
#
# Modified by Julian Sanin (2016)
#

# This script will run the necessary steps to deploy Swift on the cluster.

set -u
#set -x

readonly LOGS="$(dirname $0)/logs"
readonly LOG_FILENAME="deployment.log"

rm -r "$LOGS/"
mkdir -p "$LOGS"

source "$(dirname $0)/swman/swman.lib.sh"
source "$(dirname $0)/cluster.lib.sh"
source "$(dirname $0)/cluster.cfg.sh"

clusterInit "$CLUSTER_CONFIGURATION" 2

"$(dirname $0)/cluster.updater.sh" 2>&1 | tee -a "$LOGS/$LOG_FILENAME"
"$(dirname $0)/cluster.installer.sh" 2>&1 | tee -a "$LOGS/$LOG_FILENAME"
"$(dirname $0)/cluster.restart.sh" 2>&1 | tee -a "$LOGS/$LOG_FILENAME"

echo "    - running first test"
clusterGetPackage curl

"$(dirname $0)/examples/store_and_retrieve_character.sh" 2>&1 | tee -a "$LOGS/$LOG_FILENAME"
"$(dirname $0)/examples/store_and_retrieve_character.sh" 2>&1 | tee -a "$LOGS/$LOG_FILENAME"

echo "Done! You can find logs in the $LOGS folder."
exit 0
