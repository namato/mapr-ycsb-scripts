#!/bin/bash
#
# Run all the standard YCSB workloads A-F.
#
# Pre-conditions before running
# -----------------------------
# 
# - Assumes the load phase was done beforehand.
# 
# - Assumes 'operationcount' !=0 (in the YCSB workload
#   file or specified on the command line)
#   so the workload does not run continuously.  Another way
#   to ensure this is to set 'maxexecutiontime'.
#
# - Set $WHICHDB in this file to set the correct YCSB back-end
#
# - Set $ENVSH and $ENVSH_REMOTE to the paths of env.sh on the local
#   and remote hosts, respectively
#
# Any command line args (such as '-p xyz') are passed to
# ycsbrun.sh for the 'tran' phase.
#

source env.sh

ENVSH=/home/ubuntu/mapr-ycsb-scripts/env.sh
ENVSH_REMOTE=/home/centos/mapr-ycsb-scripts/env.sh
WHICHDB=maprdb

for w in a b c d e f; do
	echo "killing off all jobs"
	$TOOL_HOME/ycsbrun.sh $WHICHDB kill
	echo "clearing caches"
	clush -l $SSH_REMOTE_USER -g $CLUSH_NODE_GROUP -o '-t -t' \
	    "echo 3 | sudo tee /proc/sys/vm/drop_caches" > /dev/null 2>&1 
	echo "copying files for workload $w"
	sed -i $ENVSH -e s/workload[abcdef]/workload$w/
	clush -l $SSH_REMOTE_USER -g $CLUSH_NODE_GROUP -c $ENVSH --dest=$ENVSH_REMOTE
	clush -l $SSH_REMOTE_USER -g $CLUSH_NODE_GROUP -c $YCSB_HOME/workloads/workload$w \
		--dest=$YCSB_HOME/workloads/workload$w
	clush -l $SSH_REMOTE_USER -g $CLUSH_NODE_GROUP rm -f $YCSB_HOME/$FILENAME_BASE.stats
	echo "running workload $w"
	$TOOL_HOME/ycsbrun.sh $WHICHDB tran $*
	RESULTDIR_FORMAT=`date '+%Y%m%d_%T'`
	DIRSTR=$WHICHDB
	DIRSTR+='_'
	DIRSTR+=workload_
	DIRSTR+=$w
	DIRSTR+='_'
	DIRSTR+=$RESULTDIR_FORMAT
	mkdir -p $TOOL_HOME/$DIRSTR
	echo "workload $w complete, copying result files to directory $DIRSTR"
	$TOOL_HOME/ycsbrun.sh $WHICHDB copy
	mv $FILENAME_BASE.out.* $DIRSTR
	mv $FILENAME_BASE.stats.* $DIRSTR
	if ls mfs.log* 1> /dev/null 2>&1; then
		mv mfs.log* $DIRSTR
	fi
	if ls $FILENAME_BASE.maprcli* 1> /dev/null 2>&1; then
		mv $FILENAME_BASE.maprcli* $DIRSTR
	fi
	if ls $FILENAME_BASE.hadoop* 1> /dev/null 2>&1; then
		mv $FILENAME_BASE.hadoop* $DIRSTR
	fi
	if ls $FILENAME_BASE.nodetool* 1> /dev/null 2>&1; then
		mv $FILENAME_BASE.nodetool* $DIRSTR
	fi
	echo "done copying files"
done
echo "tests completed"
