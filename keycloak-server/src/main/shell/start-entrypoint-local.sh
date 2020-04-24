#!/bin/bash

INSTALL_LOG=/app/start.log

###############################################################################################################

 KEYCLOAK_USER="admin"
 echo "KEYCLOAK_USER************${KEYCLOAK_USER}"
 KEYCLOAK_PASSWORD="123456"
 echo "KEYCLOAK_PASSWORD************${KEYCLOAK_PASSWORD}"
 DB_ADDR_PORT="sagamariadb:3306"
 echo "DB_ADDR_PORT************${DB_ADDR_PORT}"
 DB_NAME="qloudpdp"
 echo "DB_NAME************${DB_NAME}"
 DB_USER="root"
 echo "DB_USER************${DB_USER}"
 DB_PASSWORD="Qloud@dev?123"
 echo "DB_PASSWORD************${DB_PASSWORD}"
 LOG_LEVEL="ERROR"
 echo "LOG_LEVEL************${LOG_LEVEL}"
 QLOUD_HA="true"
 echo "QLOUD_HA************${QLOUD_HA}"
 CACHE_OWNERS="1"
 echo "CACHE_OWNERS************${CACHE_OWNERS}"
 GROUPS_DISCOVERY_EXTERNAL_IP=$(/sbin/ifconfig eth0 | sed -nr 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
 echo "GROUPS_DISCOVERY_EXTERNAL_IP************$GROUPS_DISCOVERY_EXTERNAL_IP"


 echo "start3"
 export KEYCLOAK_USER
 export KEYCLOAK_PASSWORD
 export DB_ADDR_PORT
 export DB_NAME
 export DB_USER
 export DB_PASSWORD
 export LOG_LEVEL
 export QLOUD_HA
 export CACHE_OWNERS
 export GROUPS_DISCOVERY_EXTERNAL_IP

##################
# Add admin user #
##################
echo "Add admin user"

if [ $KEYCLOAK_USER ] && [ $KEYCLOAK_PASSWORD ]; then
    /app/target/qloudpdp-server/bin/add-user-keycloak.sh --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD
    echo "add-user-org.keycloak.sh  KEYCLOAK_USER***********$KEYCLOAK_USER   KEYCLOAK_PASSWORD********$KEYCLOAK_PASSWORD">> $INSTALL_LOG
fi

################
# Realm import #
################

echo "Realm import openbanking and qloudfin"
if [ "$KEYCLOAK_IMPORT_OPENBANKING" ]; then
    SYS_PROPS+=" -Dkeycloak.import=$KEYCLOAK_IMPORT_OPENBANKING"
fi

# system param

SYS_DB_ADDR_PORT=" -DDB_ADDR_PORT=$DB_ADDR_PORT"
SYS_DB_NAME=" -DDB_NAME=$DB_NAME"
SYS_DB_USER=" -DDB_USER=$DB_USER"
SYS_DB_PASSWORD=" -DDB_PASSWORD=$DB_PASSWORD"
SYS_LOG_LEVEL=" -DLOG_LEVEL=$LOG_LEVEL"
SYS_CACHE_OWNERS=" -DCACHE_OWNERS=$CACHE_OWNERS"
SYS_GROUPS_DISCOVERY_EXTERNAL_IP=" -DGROUPS_DISCOVERY_EXTERNAL_IP=$GROUPS_DISCOVERY_EXTERNAL_IP"

##################
# Start Keycloak #
##################
echo "Start Keycloak"

    echo "Start Keycloak  QLOUD_HA"
    exec /app/target/qloudpdp-server/bin/standalone.sh -c ../../standalone/configuration/standalone_ha.xml $SYS_DB_ADDR_PORT $SYS_DB_NAME $SYS_DB_USER $SYS_DB_PASSWORD $SYS_LOG_LEVEL $SYS_CACHE_OWNERS $SYS_GROUPS_DISCOVERY_EXTERNAL_IP $SYS_PROPS

    exit $?
