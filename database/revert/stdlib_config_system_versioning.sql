-- Revert geekspeak:stdlib_config_system_versioning from pg

BEGIN;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib;

DROP EVENT TRIGGER _52_create_system_versioned_history
                 ;

DROP FUNCTION IF EXISTS current_system_versioned()
                      , system_versioned_close(__system_versioned, timestamptz)
                      , system_versioned_insert()
                      , system_versioned_update()
                      , system_versioned_update_to_history()
                      , system_versioned_delete_to_history()
                      , system_versioned_truncate_to_history()
                      , is_history_attached(text)
                      , last_modified(__system_versioned)
                      , init_system_versioned_history(name, name, name)
                      , create_system_versioned_history()
                      , get_config(text)
                      , get_config(text, text)
                      , get_config(text, int8)
                      , get_config(text, float8)
                      , get_config(text, bool)
                      , set_config(text, text, name[], name[])
                      , set_config(text, int8, name[], name[])
                      , set_config(text, float8, name[], name[])
                      , set_config(text, bool, name[], name[])
                CASCADE
                      ;

DROP TABLE SYSTEM_VERSIONED
         , __system_versioned
         , config
   CASCADE
         ;

DROP SCHEMA system_versioning
    CASCADE
          ;

RESET search_path;

COMMIT;
