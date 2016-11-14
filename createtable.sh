#!/bin/bash

source env.sh

NN=`clush -g all -N hostname | wc -w`

TYPE=$1
shift
case "$TYPE" in 
  maprdb | hbase)
    SHELLCMD='hbase shell'
    read -r -d '' TABLEDEF << EOM
NN=$(($NN * 2))
splits=(1..(NN-1)).map {|i| "user#{10000+i*(92924-10000)/NN}"}
create '$TABLE', 'family', SPLITS => splits
EOM
     ;;
  cassandra2-cql)
    SHELLCMD='cqlsh'
    read -r -d '' TABLEDEF << EOM
create keyspace ycsb
WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor': 3 };
USE ycsb;
create table usertable (
y_id varchar primary key,
field0 varchar,
field1 varchar,
field2 varchar,
field3 varchar,
field4 varchar,
field5 varchar,
field6 varchar,
field7 varchar,
field8 varchar,
field9 varchar);
EOM
     ;;
   *) 
      echo "ERROR: Unrecognized database type: " $TYPE
      exit 1
     ;;
esac

echo "$TABLEDEF" | clush --pick=1 -g all $SHELLCMD
