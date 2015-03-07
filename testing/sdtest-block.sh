#!/bin/bash
echo "48 MiB write test, 2x repeatition:";

echo -e "\nBlock size = 4M";
echo "Test 1:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=4M count=12
rm ./test.dat
echo "Test 2:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=4M count=12
rm ./test.dat

echo "Block size = 2M";
echo "Test 1:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=2M count=24
rm ./test.dat
echo "Test 2:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=2M count=24
rm ./test.dat

echo -e "\nBlock size = 1M";
echo "Test 1:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=1M count=48
rm ./test.dat
echo "Test 2:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=1M count=48
rm ./test.dat

echo -e "\nBlock size = 512k";
echo "Test 1:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=512k count=96
rm ./test.dat
echo "Test 2:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=512k count=96
rm ./test.dat

echo -e "\nBlock size = 4k";
echo "Test 1:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=4k count=12288
rm ./test.dat
echo "Test 2:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=4k count=12288
rm ./test.dat

echo -e "\nBlock size = 2k";
echo "Test 1:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=2k count=24576
rm ./test.dat
echo "Test 2:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=2k count=24576
rm ./test.dat

echo -e "\nBlock size = 1k";
echo "Test 1:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=1k count=49152
rm ./test.dat
echo "Test 2:";
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=./test.dat bs=1k count=49152
rm ./test.dat 