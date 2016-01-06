#!/bin/bash
echo -e "\n /dev/zero tests"
echo -e "\nWrite zero bs=1M 10MiB"
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=test-a bs=1M count=10
echo -e "\nRead zero bs=1M 10MiB"
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=test-a of=/dev/null bs=1M count=10
rm test-a

echo -e "\nWrite zero bs=1M 50MiB"
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=test-b bs=1M count=50
echo -e "\nRead zero bs=1M 50MiB"
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=test-b of=/dev/null bs=1M count=50
rm test-b

echo -e "\nWrite zero bs=1M 100MiB"
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=test-c bs=1M count=100
echo -e "\nRead zero bs=1M 100MiB"
sync; echo 1 > /proc/sys/vm/drop_caches
dd if=test-c of=/dev/null bs=1M count=100
rm test-c