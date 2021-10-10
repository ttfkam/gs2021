-- Deploy geekspeak:geekspeak_role to pg
-- requires: stdlib

BEGIN;

DO $$ BEGIN IF stdlib.not_exists('role', 'geekspeak_admin') THEN

  CREATE ROLE geekspeak_admin
              LOGIN
              BYPASSRLS
              CREATEROLE
              REPLICATION
              CONNECTION LIMIT 10
            ;
END IF; END; $$ LANGUAGE plpgsql;

DO $$ BEGIN IF stdlib.not_exists('role', 'geekspeak_user') THEN

  CREATE ROLE geekspeak_user
              NOLOGIN
              NOINHERIT
            ;
END IF; END; $$ LANGUAGE plpgsql;

DO $$ BEGIN IF stdlib.not_exists('role', 'geekspeak_api') THEN

  CREATE ROLE geekspeak_api
              LOGIN
              INHERIT
            ;
        GRANT geekspeak_user
           TO geekspeak_api
            ;
END IF; END; $$ LANGUAGE plpgsql;

DO $$ BEGIN IF stdlib.not_exists('role', 'geekspeak_analysis') THEN

  CREATE ROLE geekspeak_analysis
              LOGIN
              INHERIT
              BYPASSRLS
              CONNECTION LIMIT 10
            ;
END IF; END; $$ LANGUAGE plpgsql;

 GRANT CREATE
     , USAGE
    ON SCHEMA system_versioning
    TO geekspeak_admin
     ;

COMMIT;
