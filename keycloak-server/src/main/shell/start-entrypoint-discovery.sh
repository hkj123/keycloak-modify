#!/bin/bash

export INSTALL_HOME=$(cd `dirname $0`; pwd)

if [ -n "$DISCOVERY_USED" -a "$DISCOVERY_USED" != "true" ]; then
	exit 1
fi
if [ -n "$CONFIG_USED" -a "$CONFIG_USED" != "true" ]; then
	exit 1
fi

INSTALL_LOG=/app/start.log

SCHEMA=
HOST=
PORT=
STATUS=

if [ "$DISCOVERY_SSL" = "true" ]; then
	SCHEMA="https"
else
	SCHEMA="http"
fi

if [ -z "$DISCOVERY_NAME" ]; then
	NAME="kernel"
else
	NAME="$DISCOVERY_NAME"
fi

if [ -z "$DISCOVERY_CLUSTER" ]; then
	HOST="qloudkernel"
else
	HOST=$DISCOVERY_CLUSTER
fi
if [ -z "$DISCOVERY_CLUSTER_PORT" ]; then
	PORT="8888"
else
	PORT=$DISCOVERY_CLUSTER_PORT
fi

QLOUD_SERVICE_NAME=
if [ -z "$SERVICE_NAME" ]; then
	QLOUD_SERVICE_NAME="qloudpdp"
else
	if [ "$SERVICE_NAME" != "" ]; then
		QLOUD_SERVICE_NAME="$SERVICE_NAME"
	else
		QLOUD_SERVICE_NAME="qloudpdp"
	fi
fi
if [ -z "$SERVICE_NAMESPACE" ]; then
	QLOUD_SERVICE_NAME="$QLOUD_SERVICE_NAME"
else
	if [ "$SERVICE_NAMESPACE" != "" ]; then
		QLOUD_SERVICE_NAME="$QLOUD_SERVICE_NAME.$SERVICE_NAMESPACE"
	else
		QLOUD_SERVICE_NAME="$QLOUD_SERVICE_NAME"
	fi
fi

# Try local
`nc -z -v -w 10 $HOST $PORT >> $INSTALL_LOG 2>&1`
if [  "$?" = 0 ]; then
	echo "Try local discovery succeed..." >> $INSTALL_LOG
	STATUS="true"
else
	if [ -z "$DISCOVERY_INGRESS" ]; then
		HOST="qloudkernel.service.sd"
	else
		HOST=$DISCOVERY_INGRESS
	fi
	if [ -z "$DISCOVERY_INGRESS_PORT" ]; then
		PORT="80"
	else
		PORT=$DISCOVERY_INGRESS_PORT
	fi

	# Try public
	`nc -z -v -w 10 $HOST $PORT >> $INSTALL_LOG 2>&1`
	if [  "$?" = 0 ]; then
		echo "Try public discovery succeed..." >> $INSTALL_LOG
		STATUS="false"
	else
		echo "Try all discovery failed..." >> $INSTALL_LOG
		exit 1
	fi
fi

DISCOVERY_RESULT=$(curl -k -X GET $SCHEMA://$HOST:$PORT/discovery/services/$NAME)
echo "Check discovery result...$DISCOVERY_RESULT" >> $INSTALL_LOG

echo "start1"
ADMIN_HOST=
ADMIN_PORT=

if [ "$STATUS" = "true" ]; then
	ADMIN_HOST=$(echo $DISCOVERY_RESULT | jq -r '.[0]|.ServiceMeta.LocalHost')
	ADMIN_PORT=$(echo $DISCOVERY_RESULT | jq -r '.[0]|.ServiceMeta.LocalAdminPort')
else
	ADMIN_HOST=$(echo $DISCOVERY_RESULT | jq -r '.[0]|.ServiceMeta.PublicAdminHost')
	ADMIN_PORT=$(echo $DISCOVERY_RESULT | jq -r '.[0]|.ServiceMeta.PublicAdminPort')
fi

echo "[Step 1] Check discovery security result..." >> $INSTALL_LOG
SECURITY_RESULT=$(curl -k -X GET $SCHEMA://$ADMIN_HOST:$ADMIN_PORT/__admin/security/)
ENABLE_SECURITY=$(echo $SECURITY_RESULT | jq -r '.security_enable')

CONFIG_RESULT=

JWT_TOKEN=
if [ "$ENABLE_SECURITY" = "true" ]; then
	NODE_TOKEN_RESULT=$(curl -k -X POST \
	  $SCHEMA://$HOST:$PORT/security/nodes/token \
	  -H 'Content-Type: application/json' \
	  -d '{
	  "servicename": "sysadmin",
	  "hostname": "localhost"
	}')
	echo "NODE_TOKEN_RESULT************${NODE_TOKEN_RESULT}">> $INSTALL_LOG
	NODE_TOKEN=$(echo $NODE_TOKEN_RESULT | jq -r '.token')

	JWT_TOKEN_RESULT=$(curl -k -X POST \
      $SCHEMA://$HOST:$PORT/security/pki/sign/${NODE_TOKEN} \
      -H 'Content-Type: application/json' \
      -d "{\"rolename\": \"${SERVICE_NAME:-qloudpdp}\"}")
    JWT_TOKEN=$(echo $JWT_TOKEN_RESULT | jq -r '.jwt')

    CONFIG_RESULT=$(curl -X GET \
      $SCHEMA://$HOST:$PORT/configs/${QLOUD_SERVICE_NAME:qloudpdp} \
      -H "Content-Type: application/json" \
      -H "X-Qloud-Token: $JWT_TOKEN")
    echo "CONFIG_RESULT************${CONFIG_RESULT}">> $INSTALL_LOG
else
    CONFIG_RESULT=$(curl -X GET \
      $SCHEMA://$HOST:$PORT/configs/${QLOUD_SERVICE_NAME:qloudpdp} \
      -H "Content-Type: application/json")
    echo "CONFIG_RESULT************${CONFIG_RESULT}">> $INSTALL_LOG
fi

###############################################################################################################
 QLOUD_KERNEL_URL=$SCHEMA://$HOST:$PORT
 echo "QLOUD_KERNEL_URL************${QLOUD_KERNEL_URL}">> $INSTALL_LOG
 KEYCLOAK_USER=$(echo $CONFIG_RESULT | jq -r '.payload.application.pdpConfig.keycloakUser')
 echo "KEYCLOAK_USER************${KEYCLOAK_USER}">> $INSTALL_LOG
 KEYCLOAK_PASSWORD=$(echo $CONFIG_RESULT | jq -r '.payload.application.pdpConfig.keycloakPassword')
 echo "KEYCLOAK_PASSWORD************${KEYCLOAK_PASSWORD}">> $INSTALL_LOG
 DB_ADDR_PORT=$(echo $CONFIG_RESULT | jq -r '.payload.application.pdpConfig.dbAddrPort')
 echo "DB_ADDR_PORT************${DB_ADDR_PORT}">> $INSTALL_LOG
 DB_NAME=$(echo $CONFIG_RESULT | jq -r '.payload.application.pdpConfig.dbName')
 echo "DB_NAME************${DB_NAME}">> $INSTALL_LOG
 DB_USER=$(echo $CONFIG_RESULT | jq -r '.payload.application.pdpConfig.dbUser')
 echo "DB_USER************${DB_USER}">> $INSTALL_LOG
 DB_PASSWORD=$(echo $CONFIG_RESULT | jq -r '.payload.application.pdpConfig.dbPassword')
 echo "DB_PASSWORD************${DB_PASSWORD}">> $INSTALL_LOG
 LOG_LEVEL=$(echo $CONFIG_RESULT | jq -r '.payload.application.pdpConfig.logLevel')
 echo "LOG_LEVEL************${LOG_LEVEL}">> $INSTALL_LOG
 QLOUD_HA=$(echo $CONFIG_RESULT | jq -r '.payload.application.pdpConfig.pdpha')
 echo "QLOUD_HA************${QLOUD_HA}">> $INSTALL_LOG

 QLOUD_PUBLICHOST=$(echo $CONFIG_RESULT | jq -r '.payload.system.publicHost')
 echo "QLOUD_PUBLICHOST************${QLOUD_PUBLICHOST}">> $INSTALL_LOG
 QLOUD_PUBLICPORT=$(echo $CONFIG_RESULT | jq -r '.payload.system.publicPort')
 echo "QLOUD_PUBLICPORT************${QLOUD_PUBLICPORT}">> $INSTALL_LOG
 QLOUD_LOCALHOST=$(echo $CONFIG_RESULT | jq -r '.payload.system.localHost')
 echo "QLOUD_LOCALHOST************${QLOUD_LOCALHOST}">> $INSTALL_LOG
 QLOUD_SSL=$(echo $CONFIG_RESULT | jq -r '.payload.system.ssl')
 echo "QLOUD_SSL************${QLOUD_SSL}">> $INSTALL_LOG
 QLOUD_KEYSTORE_PATH=$(echo $CONFIG_RESULT | jq -r '.payload.system.keystorePath')
 echo "QLOUD_KEYSTORE_PATH************${QLOUD_KEYSTORE_PATH}">> $INSTALL_LOG
 QLOUD_KEYSTORE_PASSWD=$(echo $CONFIG_RESULT | jq -r '.payload.system.keystorePasswd')
 echo "QLOUD_KEYSTORE_PASSWD************${QLOUD_KEYSTORE_PASSWD}">> $INSTALL_LOG

 echo "start3"
 export QLOUD_KERNEL_URL
 export QLOUD_SERVICE_NAME
 export KEYCLOAK_USER
 export KEYCLOAK_PASSWORD
 export DB_ADDR_PORT
 export DB_NAME
 export DB_USER
 export DB_PASSWORD
 export LOG_LEVEL
 export QLOUD_HA

 export QLOUD_SSL
 export QLOUD_PUBLICHOST
 export QLOUD_PUBLICPORT
 export QLOUD_LOCALHOST
 export QLOUD_KEYSTORE_PATH
 export QLOUD_KEYSTORE_PASSWD
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
SYS_QLOUD_KEYSTORE_PATH=" -DQLOUD_KEYSTORE_PATH=$QLOUD_KEYSTORE_PATH"
SYS_QLOUD_KEYSTORE_PASSWD=" -DQLOUD_KEYSTORE_PASSWD=$QLOUD_KEYSTORE_PASSWD"
SYS_LOG_LEVEL=" -DLOG_LEVEL=$LOG_LEVEL"

##################
# Start Keycloak #
##################
echo "Start Keycloak"
if [ "$QLOUD_HA" = "true" ]; then
    echo "Start Keycloak  QLOUD_HA"
    /app/target/qloudpdp-server/qloud/https.sh
    exec /app/target/qloudpdp-server/bin/standalone.sh -c ../../standalone/configuration/standalone_ha.xml $SYS_DB_ADDR_PORT $SYS_DB_NAME $SYS_DB_USER $SYS_DB_PASSWORD $SYS_QLOUD_KEYSTORE_PATH $SYS_QLOUD_KEYSTORE_PASSWD $SYS_LOG_LEVEL $SYS_PROPS
else
    if [ "$QLOUD_SSL" = "true" ]; then
        echo "Start Keycloak  QLOUD_SSL = true"
        /app/target/qloudpdp-server/qloud/https.sh
         exec /app/target/qloudpdp-server/bin/standalone.sh -c ../../standalone/configuration/standalone_server_https.xml $SYS_DB_ADDR_PORT $SYS_DB_NAME $SYS_DB_USER $SYS_DB_PASSWORD $SYS_QLOUD_KEYSTORE_PATH $SYS_QLOUD_KEYSTORE_PASSWD $SYS_LOG_LEVEL $SYS_PROPS
    else
        echo "Start Keycloak  QLOUD_SSL = false"
        exec /app/target/qloudpdp-server/bin/standalone.sh -c ../../standalone/configuration/standalone_server.xml $SYS_DB_ADDR_PORT $SYS_DB_NAME $SYS_DB_USER $SYS_DB_PASSWORD $SYS_LOG_LEVEL $SYS_PROPS
    fi
fi
    exit $?
