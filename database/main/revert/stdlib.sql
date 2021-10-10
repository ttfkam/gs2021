-- Revert geekspeak:stdlib from pg

BEGIN;

DROP SCHEMA stdlib
     CASCADE
     ;

COMMIT;
