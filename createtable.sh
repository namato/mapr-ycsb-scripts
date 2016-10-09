#!/bin/sh -ex 

source env.sh

hbase shell <<EOF
NN=10
splits=(1..(NN-1)).map {|i| "user#{10000+i*(92924-10000)/NN}"}
create '$TABLENAME', 'family', SPLITS => splits
EOF
