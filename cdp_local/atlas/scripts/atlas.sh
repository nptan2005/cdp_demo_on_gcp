#!/bin/bash
set -e

ATLAS_HOME=/opt/atlas
ATLAS_CONF=${ATLAS_HOME}/conf
ATLAS_BIN=${ATLAS_HOME}/bin

echo "[INFO] Starting Atlas as user: $(whoami)"
echo "[INFO] ATLAS_HOME = ${ATLAS_HOME}"

############################################
# FIRST TIME SETUP
############################################
if [ ! -f "${ATLAS_HOME}/.setupDone" ]; then
    echo "[INFO] First-time setup..."
    PASS_HASH=$(${ATLAS_BIN}/cputil.py -g -u admin -p admin -s | tail -1)
    echo "admin=ADMIN::${PASS_HASH}" > ${ATLAS_CONF}/users-credentials.properties
    touch ${ATLAS_HOME}/.setupDone
fi

echo "[INFO] Using external config at /opt/atlas/conf"
export ATLAS_CONF=/opt/atlas/conf
export ATLAS_OPTS="-Datlas.conf=/opt/atlas/conf"

############################################
# WAIT FOR POSTGRES
############################################
echo "[WAIT] Waiting for Postgres on atlas-postgres:5432 ..."
while ! nc -z atlas-postgres 5432; do
    sleep 1
done
echo "[WAIT] Postgres port open"

############################################
# WAIT FOR SOLR
############################################
echo "[WAIT] Waiting for Solr at http://atlas-solr:8983/solr/ ..."
until curl -s http://atlas-solr:8983/solr/ >/dev/null; do
    sleep 2
done
echo "[WAIT] Solr is reachable"

############################################
# WAIT FOR HBASE
############################################
echo "[WAIT] Waiting for HBase Master on atlas-hbase:16000 ..."
until nc -z atlas-hbase 16000; do
  echo -n "."
  sleep 2
done
echo "[WAIT] HBase Master is UP"

############################################
# START ATLAS SERVER
############################################
echo "[INFO] Launching Atlas..."
exec python3 ${ATLAS_BIN}/atlas_start.py