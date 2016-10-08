#!/bin/bash


#Simple script to perform a variety of YCSB related actions.
#by design the script has little intelligence. I don't want to obscure what YCSB is really doing.
#this script simply helps the user avoid a lot of annoying typing.

#these scripts assume clush is installed with passwordless ssh configured.
#these scripts assume there is a clush group 'all' although you can change that to any group you like

#the output from ycsb is written to $TOOL_HOME on all nodes. This must NOT be a shared directory or they will overwrite
#each other.

TOOL_HOME=$(cd "$(dirname "$0")"; pwd)

# set these  if needed for your environment. 
YCSB_HOME=/root/ycsb-0.9.0
#TOOL_HOME=/home/mapr/ycsbrun
if [ -z $WORKLOAD ]; then
  WORKLOAD=$TOOL_HOME/myworkload
fi
echo "Using workload file: $WORKLOAD"
#Nodes that will run YCSB (typically all data nodes)
CLUSH_NODE_GROUP='all'
#table names/paths for maprdb and hbase
MTABLE=/tables/ycsb
HTABLE=ycsbhbase
COLUMNFAMILY=family
# this is the number of threads used for transactional workloads
if [ -z $TRAN_THREADS ]; then
  TRAN_THREADS=75
fi
# this is the number of threads used for  load
if [ -z $LOAD_THREADS ]; then
  LOAD_THREADS=50
fi


function getdatanodes {
  #determine the nodes that are used for various commands using clush
  #you can change to 'data' to 'all' if all nodes store tables

  #this is a function because I only need to execute it for the initial commands and it doesn't have
  #to be executed when the functions are running on a data node where clush may not be available
  DATANODES=`clush -g $CLUSH_NODE_GROUP -N hostname`
  if [ $? != 0 ]; then
    echo "clush group '$CLUSH_NODE_GROUP' not defined. Please define."
    exit
  fi
  #remove newlines
  DATANODES=`echo $DATANODES |tr  '[:space:]' ' ' `
}





#functions

function func_copy() {
  #copy ycsb results. Notice that this is the only command that depends on the mapr client
  #as such it has a special option to run remotely

  echo copying YCSB results files to current directory
  #clush -g $CLUSH_NODE_GROUP --rcopy $YCSB_HOME/ycsb.out --dest .
  #clush -g $CLUSH_NODE_GROUP --rcopy $YCSB_HOME/ycsb.stats --dest .
  clush -g $CLUSH_NODE_GROUP --rcopy $TOOL_HOME/ycsb.stats --dest .
  clush -g $CLUSH_NODE_GROUP --rcopy $TOOL_HOME/ycsb.out --dest .

  if [ "$TYPE" = "maprdb" ]; then 
    #copy up to 3 of the most recent MFS-5 log files (MapR-DB output)
    #this may generate spurious errors if not there
    #this could be a lot of data
    echo copying MFS log files which can be very large. Consider disabling if space is an issue.
    #echo NOT copying MFS log files. Edit script if you want to preserve.
    clush -g $CLUSH_NODE_GROUP --rcopy /opt/mapr/logs/mfs.log-5{,.1,.2} --dest . 2>&1 |grep -v "No such file or directory"| grep -v "exited with exit code 1"
    ls mfs.log-5* > /dev/null
    if [ $? != 0 ]; then
      echo Failed to copy MFS log files. Proceeding anyway.
    else
      gzip mfs.log*
    fi

    echo collecting table information via maprcli and hadoop mfs
    maprcli table info -path $TABLE -json > maprcli.table.info
    maprcli table region list -path $TABLE -json > maprcli.table.region.list
    echo "======================" >> maprcli.table.region.list
    echo "summary info" >> maprcli.table.region.list
    echo "======================" >> maprcli.table.region.list
    grep primarynode maprcli.table.region.list |sort |uniq  -c >> maprcli.table.region.list
    hadoop mfs -lss $TABLE > hadoop.mfs
  else
    echo "Not copying anything for HBase (TBD)"
  fi
}


function func_tran() {
  #run YCSB on all nodes using one
  getdatanodes

  echo "Running YCSB test on these nodes: $DATANODES (using $TYPE with $TABLE)"

  for node in $DATANODES
  do
    set -x
    #hide the SLF4J error message
    ssh $node "cd $TOOL_HOME; WORKLOAD=$WORKLOAD $TOOL_HOME/ycsbrun.sh $TYPE tranone $* |grep -v SLF4J" &
    set +x
  done

  echo Waiting for completion
  wait
}

function func_one() {
  echo "executing single YCSB client (using $TYPE with $TABLE)"
  mode=$1
  shift
  #Very basic wrapper script for YCSB. This is intended just to avoid typing obvious redundant information.


  if [ "$mode" = "load" ]; then 
	threads=$LOAD_THREADS
  else
	threads=$TRAN_THREADS
  fi
  #leverages newer ycsb scripts (0.7.x and later)
  $YCSB_HOME/bin/ycsb $mode hbase10 -threads $threads -P $WORKLOAD -p table=$TABLE -p columnfamily=$COLUMNFAMILY -p exportfile=ycsb.stats -s $* -cp /YCSBRUN.FAKE:`hbase classpath` 2>&1 | tee ycsb.out; egrep -v "\[[A-Z\-]+\], >?[0-9]+, [0-9]+" ycsb.stats

}

function func_load() {
  #run YCSB load on all nodes using one
  getdatanodes

  echo "Running YCSB load on these nodes: $DATANODES (using $TYPE with $TABLE)"

  # override  these as needed
  numnodes=`echo $DATANODES |wc -w`
  recordcount=`grep ^recordcount $WORKLOAD  |egrep -o "[0-9]+"`

  insertstart=0
  insertcount=$((recordcount/$numnodes))

  echo "Loading a total of $recordcount records onto $numnodes nodes ($insertcount from each)"

  for node in $DATANODES
  do
    set -x
    #hide the SLF4J error message
    ssh $node "cd $TOOL_HOME; WORKLOAD=$WORKLOAD $TOOL_HOME/ycsbrun.sh $TYPE loadone -p insertstart=$insertstart -p insertcount=$insertcount $* |grep -v SLF4J" &
    set +x
    insertstart=$((insertstart + insertcount))
  done

  echo Waiting for completion
  wait
}

function func_status() {
  clush -g $CLUSH_NODE_GROUP -b tail -1 $TOOL_HOME/ycsb.out
  #clush -g $CLUSH_NODE_GROUP -b tail -1 $YCSB_HOME/ycsb.out
}

function func_kill_one() {
  #kill all but this script
  pids=$(pgrep -f YCSBRUN.FAKE | grep -v ^$$\$)
  kill $pids 2> /dev/null
}

function func_kill() {
  clush -g $CLUSH_NODE_GROUP $TOOL_HOME/ycsbrun.sh $TYPE killone
}


function func_usage() {
  echo "Usage: ycsbrun.sh <db type> <action> [additional arguments] where"
  echo "	<db type> is one of maprdb or hbase"
  echo "	<action> is one of one, all, load, copy, status, kill"
  echo "		load - run a ycsb load on all nodes (load data - run first)"
  echo "		tran - run a ycsb test on all nodes"
  echo "		loadone/tranone - run a single ycsb test from this node"
  echo "		status - report status of running ycsb tests"
  echo "		kill - kill running ycsb tests"
  echo "		copy - copy test results from a run to current directory "
  echo "Note that all, one, and load pass any additional arguments to the underlying YCSB tools"

  exit 1
}

##################
##MAIN
##################
  TYPE=$1
  action=$2
  shift
  shift
  case "$TYPE" in 
    maprdb)
       TABLE=$MTABLE
       ;;
    hbase)
       TABLE=$HTABLE
       ;;
     *) 
        echo "ERROR: Unrecognized database type: " $TYPE
        func_usage
       ;;
  esac

  case "$action" in
    tranone) 
       func_one run $*
       ;;
    loadone) 
       func_one load $*
       ;;
    tran) 
       func_tran $*
       ;;
    load) 
       func_load $*
       ;;
    copy) 
       func_copy $*
       ;;
    status) 
       func_status $*
       ;;
    kill) 
       func_kill $*
       ;;
    killone) 
       func_kill_one $*
       ;;
     *) 
        echo "ERROR: Unrecognized action: " $action
        func_usage
       ;;
  esac
