-- Revert geekspeak:stdlib_audit_ddl from pg

BEGIN;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib;

DROP EVENT TRIGGER _00_ddl_drop
                 , _00_ddl_info
                 ;

DROP FUNCTION ddl_drop_log()
            , ddl_log()
            ;

DROP TABLE ddl_info
         ;

RESET search_path;

COMMIT;