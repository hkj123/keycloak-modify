#!/bin/bash

    if [ "$LOCAL" = "true" ]; then
        echo "Start Keycloak  LOCAL = true start-entrypoint-local.sh"
        /app/target/qloudpdp-server/qloud/start-entrypoint-local.sh
    else
       /app/target/qloudpdp-server/qloud/start-entrypoint-discovery.sh
    fi

    exit $?
