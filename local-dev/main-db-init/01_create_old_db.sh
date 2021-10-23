#!/bin/sh

set -e

OLD_DB_FILE=${OLD_DB_FILE:-"/old_gs.db"}
OLD_DB_NAME=${OLD_DB_NAME:-"old_gs"}

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL

    CREATE DATABASE ${OLD_DB_NAME}
                  ;

    CREATE SCHEMA old
                ;
EOSQL

if [ -f "${OLD_DB_FILE}" ]; then
  pg_restore -d ${OLD_DB_NAME} -O -U postgres --if-exists -c "${OLD_DB_FILE}"

  psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL

    CREATE EXTENSION
       IF NOT EXISTS postgres_fdw
                   ;

           CREATE SERVER
           IF NOT EXISTS pg
    FOREIGN DATA WRAPPER postgres_fdw
                 OPTIONS ( dbname '${OLD_DB_NAME}' )
                       ;

    CREATE USER MAPPING
          IF NOT EXISTS
                    FOR ${POSTGRES_USER}
                 SERVER pg
                OPTIONS ( user     '${POSTGRES_USER}'
                        , password '${POSTGRES_PASSWORD}'
                        )
                      ;
EOSQL

fi
