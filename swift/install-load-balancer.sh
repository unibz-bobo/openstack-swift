#!/bin/bash

source configuration-default.sh

set +x

mkdir logs

cp load_balancer/haproxy_template.cfg load_balancer/haproxy.cfg.tmp
i=0
for device in $PROXY_HOSTS
do
    echo "    server s$i $device:8080 maxconn 32" >> load_balancer/haproxy.cfg.tmp
    i=$((i+1))
done

scp -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no load_balancer/haproxy.cfg.tmp root@$LOAD_BALANCER:/etc/haproxy/haproxy.cfg >> logs/$LOAD_BALANCER 2>&1

ssh -i stack_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$LOAD_BALANCER "service haproxy restart" >> logs/$LOAD_BALANCER 2>&1

rm load_balancer/haproxy.cfg.tmp

echo "Done installing the load balancer"
