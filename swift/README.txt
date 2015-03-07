##############################
Swift automatic installer
##############################

###############
Prerequisites
###############

1) Install a debian distribution (not tested on others yet)
2a) Make sure every node can be remotely accessed by ssh logging in with root user
2b) Disributed the root ssh access key around your nodes
3) Don't forget to assign a static IP to all your nodes; note them down
4) Configure your selected topology in the "swift-configuration.sh" file

At the end of this step you should have your nodes ready to be used (with a static IP!)

################################
Distribute the necessary scripts
################################

Run
    $ ./update-script.sh
This distributes the necessary script(s) for installation around your cluster

################################
Setup the proxy node(s)
################################

Run
    $ ./install-proxy-bulk.sh

This might take a while, since it has to install proxy node(s) and distribute
the configuration of the cluster around in every other node. Be patient.

################################
Setup the storage node(s)
################################

The final step is accomplished by running:

    $ ./install-storage-bulk.sh

This also takes some time.
It prepares various configurations on the storage node(s) and starts the necessary
services.

################################
Done! And now?
################################

The cluster is now ready to rock.
You only have to setup the load balancer (if any) to round robin the requests among
different proxy thus enhancing throughput and reliability.

That's all folks!

(C) 2014 Lorenzo Miori
