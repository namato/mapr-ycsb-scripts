
# set these  if needed for your environment. 

# Where you unpacked YCSB.
YCSB_HOME=/tmp/ycsb-0.11.0

# Where the scripts will run from . Discover automatically, or set it manually.
TOOL_HOME=$(cd "$(dirname "$0")"; pwd)
#TOOL_HOME=/home/mapr/ycsbrun

# Set the name of the workload file to use.
WORKLOAD=$TOOL_HOME/myworkload

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
