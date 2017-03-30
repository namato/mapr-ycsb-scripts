#!/bin/sh

# set these  if needed for your environment. 

# for docker container command line (PACC)
CLUSTER_NAME=bmk36
CLDB_HOSTS=ip-10-0-100-242

# user parameters - this uses the default user for Centos 7
# assumes 'sudo' access
MAPR_CONTAINER_USER=centos
MAPR_CONTAINER_GROUP=centos
MAPR_CONTAINER_UID=1000
MAPR_CONTAINER_GID=1000
MAPR_CONTAINER_IMAGE=maprtech/pacc:5.2.0_2.0_centos7

# this is used to copy jars to the tool directory
MAPR_HBASE_VERSION=1.1.1

# assumes ycsb and tools are copied here locally on each machine - 
# this specifies what docker volume to mount so we can access the
# tools in the container
MAPR_CONTAINER_BASEDIR=/home/centos

# Where you unpacked YCSB.
YCSB_HOME=/home/centos/ycsb-0.12.0 
#YCSB_HOME=/home/centos/YCSB
#YCSB_HOME=/home/centos/ycsb-0.13.0-SNAPSHOT 

# user under which to run the YCSB tools on the remote nodes
SSH_REMOTE_USER=centos

# Where the scripts will run from . Discover automatically, or set it manually.
#TOOL_HOME=$(cd "$(dirname "$0")"; pwd)
#TOOL_HOME=/home/mapr/ycsbrun
TOOL_HOME=/home/centos/mapr-ycsb-scripts

# Set the name of the workload file to use.
WORKLOAD=$YCSB_HOME/workloads/workloada

# Nodes that will run YCSB (typically all data nodes)
CLUSH_NODE_GROUP='all'

# table names/paths for maprdb and hbase
# flat tables (no path hierarchy) for HBase
TABLE=/bb/ycsb
COLUMNFAMILY=family

# this is the number of threads used for transactional workloads
TRAN_THREADS=70

# this is the number of threads used for  load
LOAD_THREADS=40

# this is the base filename for all output files, each of which
# have a different extension.  For example, if you set this to 'ycsb',
# the files will be named ycsb.out, ycsb.stats, etc. 
# This can be used to run the test multiple times from the same directory and 
# differentiate the output files.
FILENAME_BASE=maprdb
