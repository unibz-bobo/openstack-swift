#!/bin/bash

CWD=$(pwd)
echo "OS filesystem testing"
# Standard filesystem
# 2 tests twice interleaved
rm block.log
rm zero.log
./sdtest-block.sh >> block.log 2>&1
./sdtest-zero.sh >> zero.log 2>&1

# Swift storage
cd /srv/node/sdb1
echo "Swift filesystem testing"
rm $CWD/block-swift.log
rm $CWD/zero-swift.log
$CWD/sdtest-block.sh >> $CWD/block-swift.log 2>&1
$CWD/sdtest-zero.sh >> $CWD/zero-swift.log 2>&1
