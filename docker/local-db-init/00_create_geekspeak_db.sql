
  CREATE ROLE geekspeak_admin
              LOGIN
              PASSWORD 'demo'
              BYPASSRLS
              CREATEROLE
              REPLICATION
              CONNECTION LIMIT 10
            ;

  CREATE ROLE geekspeak_user
              NOLOGIN
            ;

  CREATE ROLE geekspeak_api
              LOGIN
              PASSWORD 'demo'
              NOINHERIT
            ;
        GRANT geekspeak_user
           TO geekspeak_api
            ;

CREATE DATABASE geekspeak
          OWNER geekspeak_admin
              ;
