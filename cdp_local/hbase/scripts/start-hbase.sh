#!/bin/bash
set -e

mkdir -p /opt/hbase/logs

echo "Starting HBase Master..."
/opt/hbase/bin/hbase master start &

sleep 5

echo "Starting HBase RegionServer..."
/opt/hbase/bin/hbase regionserver start &

sleep 3

echo "HBase started. Tail logs..."
tail -F /opt/hbase/logs/*