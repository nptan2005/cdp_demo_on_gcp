#!/bin/bash
set -e

export HBASE_HOME=/opt/hbase
export PATH=$PATH:$HBASE_HOME/bin

echo "[INFO] Starting HBase..."

# Optional first-time setup
if [ ! -f "${HBASE_HOME}/.setupDone" ]; then
    echo "export JAVA_HOME=${JAVA_HOME}" >> ${HBASE_HOME}/conf/hbase-env.sh
    touch ${HBASE_HOME}/.setupDone
fi

# Start HBase daemons
$HBASE_HOME/bin/start-hbase.sh

sleep 5

echo "[INFO] Checking HBase processes..."
jps

MASTER_PID=$(jps | grep HMaster | awk '{print $1}')
if [ -z "$MASTER_PID" ]; then
    echo "[ERROR] HMaster did not start!"
    exit 1
fi

# Keep container alive
echo "[INFO] HBase started. Tail logs..."
tail -F $HBASE_HOME/logs/*