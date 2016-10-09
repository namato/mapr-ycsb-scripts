# Overview

This is a bunch of scripts to assist with running YCSB. There's also some guidance on setting up clustershell, which is a prerequistite.

# Clone this repo to `/tmp`

```
git clone https://github.com/vicenteg/mapr-ycsb-scripts.git /tmp/mapr-ycsb-scripts
```

# Get and unpack YCSB

YCSB 0.11.0 is the latest as of this writing. Use that one, or adjust the URL below as needed.

If you don't want to unpack to `/tmp`, change that too. Pick a destination with enough space. 0.11.0 is about 350MB unpacked.

```
curl -L https://github.com/brianfrankcooper/YCSB/releases/download/0.11.0/ycsb-0.11.0.tar.gz | tar -C /tmp -vxzf -
```

# Set up clustershell

I am assuming that you can find and install python 2.7 and virtualenv for your OS. I use CentOS, and on CentOS, I can get virtualenv via yum with `yum -y install python-virtualenv`.

Create a new virtualenv for clustershell:

```
virtualenv clustershell
pip install -r clustershell-requirements.txt
```

Look at all the files in `dot_local`. Edit them as necessary. Primarily, you need to edit the following:

`dot_local/etc/clustershell/clush.conf`: Set the remote username and your private keyfile location.
`dot_local/etc/clustershell/groups.d/local.cfg`: Edit the line starting with `all` to be a space-delimited list of the hostnames in your cluster. There are examples of different ways to write the list, but the `all` group must exist.

Then copy `dot_local` to `~/.local`. I used `-n` on cp to avoid clobbering existing files. You can remove that option if need be.

```
cp -nr dot_local ~/.local
```

If this all went according to plan, you should be able to run `clush -ab date` and get output similar to the following:

```
$ clush -ab date
---------------
172.16.2.[4-9] (6)
---------------
Sun Oct  9 12:21:01 EDT 2016
```

Clustershell is set up. Nice work.

# Set up ycsbrun.sh

Configuration of this script should happen by setting variables in `env.sh` in the root of this repository. Comments in that file should be self-explanatory.

# Set up the cluster nodes

Now that YCSB is unpacked, clustershell works, and these scripts are set up, you can push this stuff out to all the nodes.

```
clush -ac /tmp/ycsb-* /tmp/mapr-ycsb-scripts
``

# Create the table

Having set up env.sh you should have set a table name. Let's create it:

```
./createtable.sh
```

This will use clustershell to pick a node at random from the cluster to create the table via the hbase shell. You need to pay attention to the output here, and make sure it completes successfully. Return code will be 0 even if it fails.


