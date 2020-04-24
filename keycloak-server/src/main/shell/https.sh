#!/bin/bash

function autogenerate_keystores() {

  local KEYSTORES_STORAGE="${QLOUD_KEYSTORE_PATH}"
  if [ ! -d "${KEYSTORES_STORAGE}" ]; then
    mkdir -p "${KEYSTORES_STORAGE}"
  fi

    local X509_KEYSTORE_DIR="/etc/qloudtls"
    local X509_CLIENT_KEYSTORE_DIR="/etc/qloudtls"
    local X509_CRT="tls.crt"
    local X509_KEY="tls.key"
    local X509_ROOT_CRT="ca.crt"
    local X509_CLIENT_CRT="ca.crt"
    local NAME="obp-https-key"
    local CLIENT_NAME="service-client-ca"
    local PASSWORD="${QLOUD_KEYSTORE_PASSWD}"
    local JKS_KEYSTORE_FILE="https-keystore.jks"
    local PKCS12_KEYSTORE_FILE="https-keystore.pk12"


    if [ -d "${X509_KEYSTORE_DIR}" ]; then

      echo "Creating ${KEYSTORES[$KEYSTORE_TYPE]} keystore via OpenShift's service serving x509 certificate secrets.."

      openssl pkcs12 -export \
      -name "${NAME}" \
      -inkey "${X509_KEYSTORE_DIR}/${X509_KEY}" \
      -in "${X509_KEYSTORE_DIR}/${X509_CRT}" \
      -out "${KEYSTORES_STORAGE}/${PKCS12_KEYSTORE_FILE}" \
      -password pass:"${PASSWORD}" >& /dev/null

      echo "1"

      keytool -importkeystore -noprompt \
      -srcalias "${NAME}" -destalias "${NAME}" \
      -srckeystore "${KEYSTORES_STORAGE}/${PKCS12_KEYSTORE_FILE}" \
      -srcstoretype pkcs12 \
      -destkeystore "${KEYSTORES_STORAGE}/${JKS_KEYSTORE_FILE}" \
      -storepass "${PASSWORD}" -srcstorepass "${PASSWORD}" >& /dev/null

      if [ -f "${KEYSTORES_STORAGE}/${JKS_KEYSTORE_FILE}" ]; then
        echo "SERVER ${KEYSTORES[$KEYSTORE_TYPE]} keystore successfully created at: ${KEYSTORES_STORAGE}/${JKS_KEYSTORE_FILE}"
      fi
    fi


  # Auto-generate the Keycloak truststore if X509_CA_BUNDLE was provided
  local -r X509_CRT_DELIMITER="/-----BEGIN CERTIFICATE-----/"
  local JKS_TRUSTSTORE_FILE="truststore.jks"
  local JKS_TRUSTSTORE_PATH="${KEYSTORES_STORAGE}/${JKS_TRUSTSTORE_FILE}"
  local PASSWORD="${PASSWORD}"

    echo "Creating Keycloak truststore.."

    keytool -import -noprompt -keystore "${JKS_TRUSTSTORE_PATH}" -file "${X509_CLIENT_KEYSTORE_DIR}/${X509_ROOT_CRT}" \
    -storepass "${PASSWORD}" -alias "${CLIENT_NAME}" >& /dev/null

    if [ -f "${JKS_TRUSTSTORE_PATH}" ]; then
      echo "Keycloak truststore successfully created at: ${JKS_TRUSTSTORE_PATH}"
    fi
}

autogenerate_keystores
