#!/usr/env python

import collections
import sys

LOAD_BALANCER = "10.10.242.55"
HOSTS = "10.10.242.97 10.10.242.98 10.10.242.99 10.10.242.56 10.10.242.12 10.10.242.52 10.10.242.54 10.10.242.6 10.10.242.10 10.10.242.8 10.10.242.45 10.10.242.46 10.10.242.47 10.10.242.48 10.10.242.49 10.10.242.50 10.10.242.53 10.10.242.7 10.10.242.9 10.10.242.51 10.10.242.11 10.10.242.57 10.10.242.59 10.10.242.60 10.10.242.61 10.10.242.62"

HOSTS = HOSTS.split(" ")


TEMPLATE = """
#!/bin/bash

# Description
#
# THIS CONFIGURATION HAS BEEN AUTOMATICALLY GENERATED!!
#   DO NOT HAND-EDIT!!
# Total nodes: TOTALNODES (NODESINUSE in use)
# XNPROXY Proxies ; XNACCOUNT Accounts ; XNCONTAINER Containers ; XNOBJECT Object
# Single zone, single region

# specific settings for proxy
PROXY_HOSTS="DEF_PROXY_HOSTS"
# NOTE this is the proxy that is first configured
MASTER_PROXY="DEF_MASTER_PROXY"
LOAD_BALANCER="10.10.242.55"

# specific settings for storage
ACCOUNT_HOSTS="DEF_ACCOUNT_HOSTS"
CONTAINER_HOSTS="DEF_CONTAINER_HOSTS"
OBJECT_HOSTS="DEF_OBJECT_HOSTS"

# does the script have to create separate zones ?
# at the moment, a zone is a single group account-container-object
CREATE_ZONES=1

# Replication count
REPLICATION=DEF_REPLICATION

# Partition power (2^n)
PARTITIONS=7
"""

duplicates = [x for x, y in collections.Counter(HOSTS).items() if y > 1]

if len(duplicates) > 0:
    print "Duplicate(s) in HOSTS list found: %s" % str(duplicates)
    sys.exit(1)

print "Totals:"
TOTALNODES=len(HOSTS)
print "%i hosts" % len(HOSTS)

used_hosts = 0
proxies = []
accounts = []
containers = []
objects = []

def check():
    return len(HOSTS) != 0

while check():

    if check():
        proxies.append(HOSTS.pop(0))
    if check():
        accounts.append(HOSTS.pop(0))
    if check():
        containers.append(HOSTS.pop(0))
    if check():
        objects.append(HOSTS.pop(0))
    
    

#for i in range(0, len(HOSTS) / 4):

#    print "Nodes per service: %i" % i

#    if (len(proxies) + len(accounts) + len(containers) + len(objects)) > len(HOSTS):
#        print "overflow! Giving the rest as proxies..."
#        HOSTS.remove(x)
#        proxies += HOSTS[len(proxies) + len(accounts) + len(containers) + len(objects) - 4]
#    else:
#        for i in xrange(0, i+1):
#            print i
#            proxies.append(HOSTS.pop(0))
#            accounts.append(HOSTS.pop(0))
#            containers.append(HOSTS.pop(0))
#            objects.append(HOSTS.pop(0))

    CUR_TEMPLATE = "%s" % TEMPLATE

    CUR_TEMPLATE = CUR_TEMPLATE.replace("XNPROXY", "%i"%len(proxies))
    CUR_TEMPLATE = CUR_TEMPLATE.replace("XNACCOUNT", "%i"%len(accounts))
    CUR_TEMPLATE = CUR_TEMPLATE.replace("XNCONTAINER", "%i"%len(containers))
    CUR_TEMPLATE = CUR_TEMPLATE.replace("XNOBJECT", "%i"%len(objects))
    CUR_TEMPLATE = CUR_TEMPLATE.replace("TOTALNODES", "%i"%TOTALNODES)
    CUR_TEMPLATE = CUR_TEMPLATE.replace("NODESINUSE", "%i"%(len(proxies) + len(accounts) + len(containers) + len(objects)))

    CUR_TEMPLATE = CUR_TEMPLATE.replace("DEF_PROXY_HOSTS", " ".join(proxies))
    CUR_TEMPLATE = CUR_TEMPLATE.replace("DEF_MASTER_PROXY", proxies[0])
    CUR_TEMPLATE = CUR_TEMPLATE.replace("DEF_ACCOUNT_HOSTS", " ".join(accounts))
    CUR_TEMPLATE = CUR_TEMPLATE.replace("DEF_CONTAINER_HOSTS", " ".join(containers))
    CUR_TEMPLATE = CUR_TEMPLATE.replace("DEF_OBJECT_HOSTS", " ".join(objects))
    replica = min([len(accounts), len(containers), len(objects)])
    if replica > 3:
        replica = 3
    CUR_TEMPLATE = CUR_TEMPLATE.replace("DEF_REPLICATION", "%i" % replica)

    config_file = open("%iA%iC%iO%iP.sh" % (len(accounts), len(containers), len(objects), len(proxies)), "w")

    config_file.write(CUR_TEMPLATE)

    config_file.close()

    print CUR_TEMPLATE
