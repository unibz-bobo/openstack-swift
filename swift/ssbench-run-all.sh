#!/bin/bash

AUTHURL="http://10.10.242.99:8080/auth/v1.0/"
USER="system:root"
KEY="testpass"
# NOTE: this number here is also related to available proxy servers (behind load balancer)
WORKERS=3

mkdir ssbench-logs

for t in `ls ssbench/scenarios`
do
    echo "$t"
    ssbench-master run-scenario -f ssbench/scenarios/$t -u 4 -c 80 -o 613 --pctile 50 --workers $WORKERS -V 1.0 -U $USER -K $KEY -A $AUTHURL 2>&1 | tee ssbench-logs/$t.log
done
