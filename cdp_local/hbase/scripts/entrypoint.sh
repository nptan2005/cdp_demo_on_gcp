#!/bin/bash
set -e

echo "Starting HBase Master (Atlas mode)..."

# Ensure permissions
mkdir -p /data/hbase
chown -R root:root /data/hbase

# Standalone mode (Atlas-compatible)
${HBASE_HOME}/bin/hbase master start