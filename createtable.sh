#!/bin/bash

source env.sh

NN=`clush -g all -N hostname | wc -w`

read -r -d '' TABLEDEF << EOM
NN=$(($NN * 2))
splits=(1..(NN-1)).map {|i| "user#{10000+i*(92924-10000)/NN}"}
create '$TABLE', 'family', SPLITS => splits
EOM

echo "$TABLEDEF" | clush --pick=1 -g all hbase shell
