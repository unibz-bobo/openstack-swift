#!/bin/bash

# This script will run every configuration that is found in the configurations folder

LOGS="ssbench-logs"

mkdir -p $LOGS

set +x

if [ $# -gt 0 ]
then
    echo "manually selecting benchs"
    CONFIGS="$@"
else
    echo "starting all benchs"
    CONFIGS=$(ls configurations)
fi
echo "$CONFIGS"

mv configuration-default.sh configuration-default.sh.default

for config in $CONFIGS
do
    if [[ "$config" == *.sh ]]
    then
        echo "Deploying and benchmarking $config"
        echo "    - creating configuration file"
        echo "source configurations/$config" > configuration-default.sh 2>&1
        source configuration-default.sh
        echo "    - running deployment"
        ./update-script.sh > $LOGS/$config.log 2>&1
        ./install-proxy-bulk.sh >> $LOGS/$config.log 2>&1
        ./install-storage-bulk.sh >> $LOGS/$config.log 2>&1
        ./install-load-balancer.sh >> $LOGS/$config.log 2>&1
        echo "    - running first test"
        examples/store_and_retrieve_character.sh >> $LOGS/$config.log 2>&1
        examples/store_and_retrieve_character.sh >> $LOGS/$config.log 2>&1
        echo "    - running ssbench"
        WORKERS=3
        USERS=8
        echo "        - first run"
        echo "            - zero_byte_upload"
        ssbench-master run-scenario -f ssbench/scenarios/zero_byte_upload.scenario -u $USERS -c 80 -o 613 --pctile 50 --workers $WORKERS -V 1.0 -U system:root -K testpass -A http://$LOAD_BALANCER:8080/auth/v1.0/ >> $LOGS/$config.log 2>&1
        echo "            - small_test.scenario"
        ssbench-master run-scenario -f ssbench/scenarios/small_test.scenario -u $USERS -c 80 -o 613 --pctile 50 --workers $WORKERS -V 1.0 -U system:root -K testpass -A http://$LOAD_BALANCER:8080/auth/v1.0/ >> $LOGS/$config.log 2>&1
        echo "        - second run"
        echo "            - zero_byte_upload"
        ssbench-master run-scenario -f ssbench/scenarios/zero_byte_upload.scenario -u $USERS -c 80 -o 613 --pctile 50 --workers $WORKERS -V 1.0 -U system:root -K testpass -A http://$LOAD_BALANCER:8080/auth/v1.0/ >> $LOGS/$config.log 2>&1
        echo "            - small_test.scenario"
        ssbench-master run-scenario -f ssbench/scenarios/small_test.scenario -u $USERS -c 80 -o 613 --pctile 50 --workers $WORKERS -V 1.0 -U system:root -K testpass -A http://$LOAD_BALANCER:8080/auth/v1.0/ >> $LOGS/$config.log 2>&1

    fi
done

rm configuration-default.sh
mv configuration-default.sh.default configuration-default.sh

echo "Done! You can find logs in the $LOGS folder."
