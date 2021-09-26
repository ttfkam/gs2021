-- Deploy geekspeak:geekspeak_role to pg
-- requires: stdlib

BEGIN;

DO $$ BEGIN IF not_exists('role', 'geekspeak_admin') THEN

  CREATE ROLE geekspeak_admin
              CREATEROLE
              LOGIN
              REPLICATION
              BYPASSRLS
              CONNECTION LIMIT 10
            ;
END IF; END; $$ LANGUAGE plpgsql;

DO $$ BEGIN IF not_exists('role', 'geekspeak_app') THEN

  CREATE ROLE geekspeak_app
              LOGIN
            ;
END IF; END; $$ LANGUAGE plpgsql;

DO $$ BEGIN IF not_exists('role', 'geekspeak_analysis') THEN

  CREATE ROLE geekspeak_analysis
              LOGIN
              BYPASSRLS
              CONNECTION LIMIT 10
            ;
END IF; END; $$ LANGUAGE plpgsql;

COMMIT;
