#!/bin/bash
source configuration-default.sh
AUTHURL="http://$LOAD_BALANCER:8080/auth/v1.0/"
#AUTHURL="http://127.0.0.1:8080/auth/v1.0/"
#AUTHURL="http://10.10.242.19:8080/auth/v1.0/"
#AUTHURL="http://10.10.241.210:8080/auth/v1.0/"
USER="system:root"
KEY="testpass"
# NOTE: this number here is also related to available proxy servers (behind load balancer)
WORKERS=4

mkdir ssbench-logs

for t in very_small.scenario zero_byte_upload.scenario; do # `ls ssbench/scenarios`
    echo "$t"
    ssbench-master run-scenario -f ssbench/scenarios/$t -u 4 -c 80 -o 613 --pctile 50 --workers $WORKERS -V 1.0 -U $USER -K $KEY -A $AUTHURL 2>&1 | tee ssbench-logs/$t.log
done
