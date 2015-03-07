#!/bin/bash

#    Get an X-Storage-Url and X-Auth-Token:

curl -k -v -H 'X-Storage-User: system:root' -H 'X-Storage-Pass: testpass' https://$PROXY_LOCAL_NET_IP:8080/auth/v1.0

#    Check that you can HEAD the account:

curl -k -v -H 'X-Auth-Token: <token-from-x-auth-token-above>' <url-from-x-storage-url-above>

#Check that swift works (at this point, expect zero containers, zero objects, and zero bytes):

swift -A https://$PROXY_LOCAL_NET_IP:8080/auth/v1.0 -U system:root -K testpass stat

#Use swift to upload a few files named ‘bigfile[1-2].tgz’ to a container named ‘myfiles’:

#swift -A https://$PROXY_LOCAL_NET_IP:8080/auth/v1.0 -U system:root -K testpass upload myfiles bigfile1.tgz
#swift -A https://$PROXY_LOCAL_NET_IP:8080/auth/v1.0 -U system:root -K testpass upload myfiles bigfile2.tgz

#Use swift to download all files from the ‘myfiles’ container:

#swift -A https://$PROXY_LOCAL_NET_IP:8080/auth/v1.0 -U system:root -K testpass download myfiles

#Use swift to save a backup of your builder files to a container named ‘builders’. Very important not to lose your builders!:

swift -A https://$PROXY_LOCAL_NET_IP:8080/auth/v1.0 -U system:root -K testpass upload builders /etc/swift/*.builder

#Use swift to list your containers:

swift -A https://$PROXY_LOCAL_NET_IP:8080/auth/v1.0 -U system:root -K testpass list

#Use swift to list the contents of your ‘builders’ container:

swift -A https://$PROXY_LOCAL_NET_IP:8080/auth/v1.0 -U system:root -K testpass list builders

#Use swift to download all files from the ‘builders’ container:

swift -A https://$PROXY_LOCAL_NET_IP:8080/auth/v1.0 -U system:root -K testpass download builders

