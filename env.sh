#!/bin/sh

# set these  if needed for your environment. 

# Where you unpacked YCSB.
YCSB_HOME=/home/ubuntu/ycsb-0.11.0 

# user under which to run the YCSB tools on the remote nodes
SSH_REMOTE_USER=`whoami`

# Where the scripts will run from . Discover automatically, or set it manually.
TOOL_HOME=$(cd "$(dirname "$0")"; pwd)
#TOOL_HOME=/home/mapr/ycsbrun

# Set the name of the workload file to use.
WORKLOAD=$YCSB_HOME/workloads/workloadf

# Nodes that will run YCSB (typically all data nodes)
CLUSH_NODE_GROUP='all'

# table names/paths for maprdb and hbase
# flat tables (no path hierarchy) for HBase
TABLE=/tables/ycsb
COLUMNFAMILY=family

# this is the number of threads used for transactional workloads
TRAN_THREADS=75

# this is the number of threads used for  load
LOAD_THREADS=50

# this is the base filename for all output files, each of which
# have a different extension.  For example, if you set this to 'ycsb',
# the files will be named ycsb.out, ycsb.stats, etc. 
# This can be used to run the test multiple times from the same directory and 
# differentiate the output files.
FILENAME_BASE=cass2cql
