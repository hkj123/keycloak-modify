FROM reg.qloudhub.com/qloudservice/qloudbase:1.0.1

RUN apt-get update
RUN apt-get install zip unzip
RUN unzip -o /app/target/qloudpdp-server.zip -d /app/target/qloudpdp-server
RUN rm -rf /app/target/qloudpdp-server.zip
ENV KEYCLOAK_IMPORT_OPENBANKING /app/realm/realm-openbanking-with-algo-ps256.json
ENV KEYCLOAK_IMPORT_QLOUDFIN /app/realm/realm-qloudfin.json


COPY src/main/realm/ /app/realm/
RUN chmod u+x /app/target/qloudpdp-server/qloud/start-entrypoint.sh
RUN chmod u+x /app/target/qloudpdp-server/qloud/start-entrypoint-local.sh
RUN chmod u+x /app/target/qloudpdp-server/qloud/start-entrypoint-discovery.sh
RUN chmod u+x /app/target/qloudpdp-server/qloud/https.sh
RUN chmod u+x /app/target/qloudpdp-server/bin/standalone.sh
RUN chmod u+x /app/target/qloudpdp-server/bin/add-user-keycloak.sh
