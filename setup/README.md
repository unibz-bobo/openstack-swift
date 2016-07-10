# Swift automatic installer

## Quick guide

1. Install a Debian or Arch Linux distribution (not tested on others yet)
2. Setup each node
  * Setup every node such that it gets assigned a **static IP** address
  * Create a new xml file within the **configurations** folder; you can look at/copy from existing files as examples for the new configuration
  * Reference the new xml configuration file from within the **cluster.cfg.sh** file
  * Make sure every node can be remotely accessed by ssh logging in with root user; to do that exeecute the **cluster.distribute.keys.sh** script to drop the ssh key on to your nodes
3. Start the deployment with the **cluster.deploy.sh** script
4. Benchmark the cluster
  * Install **ssbench** on your computer with `$ sudo pip2 install ssbench`
  * Test the cluster with the **cluster.benchmark.sh** script
5. Rinse and repeat with different settings to optimze your cluster

At the end of this step you should have your nodes ready to be used (with a static IP!)

### Necessary scripts

Run `$ ./cluster.distribute.keys.sh`

This distributes the necessary SSH keys around your cluster

### Setup the node(s)

Run `$ ./cluster.deploy.sh`

This might take a while, since it has to install/update each node(s) and
distribute the configuration of the cluster around in every node. Be patient.

### Benchmarking

The final step is accomplished by running `$ ./cluster.benchmark.sh`

This also takes some time. It will run a very small and a zero upload test scenario.
At the end it will show you the results for througput in operations/second.

### Services not starting after shutting down the nodes?

Try to run `$ ./cluster.restart.sh`

It will relaunch the OpenStack Swift services.

### Script not starting because of missing files?

It is very likely that you checked out the source code repository without its *submodules*.
Execute `$ git submodule init && git submodule update` to checkout the submodules and rerun again the scripts.

### Logging

A log of the deployment phase can be found under: *logs/deployment.log*.

The benchmark will be logged to the *ssbench-logs* folder.

### Done! And now?

The cluster is now ready to rock.
Play around with the settings to optimize the performance of the cluster.

That's all folks!

(C) 2014-2016 Lorenzo Miori & Julian Sanin
