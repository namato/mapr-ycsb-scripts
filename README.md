# Overview

This is a fork of
[vicenteg/mapr-ycsb-scripts](http://github.com/vicenteg/mapr-ycsb-scripts)
that adds support for running YCSB against multiple databases.  At the
present time, only Cassandra, MapR-DB and HBase are supported.

The scripts are intended to be run from a 'driver' machine, which has connectivity
and a 'clush' configuration for a cluster of database machines.  Each machine in that
cluster will be loaded with a client instance of YCSB.

Check the original repo above for instructions for installing clustershell, etc.

# Prerequisites

- Clustershell (clush) is installed on the 'driver' machine
- YCSB binaries exist on the 'driver' and all cluster machines
- This repo exists on the 'driver' machine and all cluster machines
- Your database of choice has been configured on the cluster machines

# Quick Start

## Ensure prerequisites are met

Ensure that clustershell is installed, the 'all' group (or your preferred clush group) 
is configured, and all above prerequisites have been meet.

## Set up ycsbrun.sh

Configuration of this script should happen by setting variables in
`env.sh` in the root of this repository. Comments in that file should
be self-explanatory.

## Set up runall.sh

Edit the variables at the top of that file to match your environment.

## Create the table

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

This will use clustershell to pick a node at random from the cluster to
create the table via the hbase shell. You need to pay attention to the
output here, and make sure it completes successfully. Return code will
be 0 even if it fails.

## Edit workload files

Edit the files in $YCSB_ROOT/workloads, or wherever you are keeping workload files as 
you defined in env.sh above, to match your desired test scenario(s).

## Load the table

Execute the load phase, using all nodes of the cluster to load data.

```
./ycsbrun.sh maprdb load
```

You should see reams of output. Do not panic. Or do. It's a free
country. Look for things that look like errors. There may be things that
look like errors that are not errors. Sorry, I didn't write the software.

By default, this will load half a billion rows into the table, which
can take a while. You will see periodic status updates like this:

```
2016-10-09 13:09:52:216 610 sec: 886342 operations; 1326.6 current ops/sec; est completion in 15 hours 45 minutes [INSERT: Count=13266, Max=509439, Min=1274, Avg=3729.79, 90=4083, 99=15807, 99.9=250751, 99.99=360447]
```

## Run your workload

To run all the standard YCSB workloads A-F, use the 'runall' script as
follows (this example is for Cassandra):

```
./runall.sh -p cassandra.readconsistencylevel=THREE -p cassandra.writeconsistencylevel=THREE -p hosts='casshost' -p cassandra.keyspace='ycsb'
```

This will run all workloads and create directories like 'cass33_workload_a_YYYYMMDD:HH:MM:SS'
where the output files will be copied.

