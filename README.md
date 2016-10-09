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

Create a new virtualenv for clustershell, activate the virtualenv, then install clustershell:

```
virtualenv clustershell
source clustershell/bin/activate
pip install -r clustershell-requirements.txt
```

Now to configure clustershell.

Look at all the files in `dot_local`. Edit them as necessary. Primarily, you need to edit the following:

`dot_local/etc/clustershell/clush.conf`: Set the remote username and your private keyfile location.
`dot_local/etc/clustershell/groups.d/local.cfg`: Edit the line starting with `all` to be a space-delimited list of the hostnames in your cluster. There are examples of different ways to write the list, but the `all` group must exist.

Then copy `dot_local` to `~/.local`. I used `-n` on cp to avoid clobbering existing files, just to be safe. You can remove that option if need be.

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
```

# Create the table

Having set up env.sh you should have set a table name. Let's create it:

```
./createtable.sh
```

Your output should be similar to (table name and NN may vary, of course):

```
$ ./createtable.sh
172.16.2.8: HBase Shell; enter 'help<RETURN>' for list of supported commands.
172.16.2.8: Type "exit<RETURN>" to leave the HBase Shell
172.16.2.8: Version 1.1.1-mapr-1602, rb861ca48ca25c69cf7f02b64b7a3d5c92dc310c5, Mon Feb 22 20:52:10 UTC 2016
172.16.2.8:
172.16.2.8: Not all HBase shell commands are applicable to MapR tables.
172.16.2.8: Consult MapR documentation for the list of supported commands.
172.16.2.8:
172.16.2.8: NN=12
172.16.2.8: 12
172.16.2.8: splits=(1..(NN-1)).map {|i| "user#{10000+i*(92924-10000)/NN}"}
172.16.2.8: ["user16910", "user23820", "user30731", "user37641", "user44551", "user51462", "user58372", "user65282", "user72193", "user79103", "user86013"]
172.16.2.8: create '/tables/ycsb4', 'family', SPLITS => splits
172.16.2.8: 0 row(s) in 0.2510 seconds
172.16.2.8:
172.16.2.8: Hbase::Table - /tables/ycsb4
```

This will use clustershell to pick a node at random from the cluster to create the table via the hbase shell. You need to pay attention to the output here, and make sure it completes successfully. Return code will be 0 even if it fails.

# Load the table

Execute the load phase, using all nodes of the cluster to load data.

```
./ycsbrun.sh maprdb load
```

You should see reams of output. Do not panic. Or do. It's a free country. Look for things that look like errors. There may be things that look like errors that are not errors. Sorry, I didn't write the software.

By default, this will load half a billion rows into the table, which can take a while. You will see periodic status updates like this:

```
2016-10-09 13:09:52:216 610 sec: 886342 operations; 1326.6 current ops/sec; est completion in 15 hours 45 minutes [INSERT: Count=13266, Max=509439, Min=1274, Avg=3729.79, 90=4083, 99=15807, 99.9=250751, 99.99=360447]
```

# Run your workload

You can run your workload as follows:

```
./ycsbrun.sh maprdb tran
```

"tran" is short for "transactions", I guess.

At the end of the run, you will get a couple of files.
