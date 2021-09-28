-- Deploy geekspeak:stdlib_audit_ddl to pg

BEGIN;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public;

CREATE TABLE ddl_info (
         app_user name
,       role_name name
,    session_role name
,         classid oid
,           objid oid
,        objsubid int4
,     command_tag text
,        original bool
,          normal bool
,    is_temporary bool
,     object_type text
,     schema_name text
,     object_name text
, object_identity text
,    in_extension bool
,   address_names text[]
,    address_args text[]
,  transaction_id int8 NOT NULL
                  DEFAULT txid_current()
,        inserted timestamptz NOT NULL
                  DEFAULT clock_timestamp()
-- No need to be system versioned since it's basically just a structured log
); COMMENT ON TABLE ddl_info IS
'@ignore-lint RELATION_PRIMARY_KEY DDL debug logging table.
Columns map to event trigger metadata: https://www.postgresql.org/docs/current/functions-event-triggers.html';

CREATE FUNCTION ddl_drop_log()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
  BEGIN
    INSERT INTO stdlib.ddl_info ( app_user
                                , role_name
                                , session_role
                                , classid
                                , objid
                                , objsubid
                                , original
                                , normal
                                , is_temporary
                                , object_type
                                , schema_name
                                , object_name
                                , object_identity
                                , address_names
                                , address_args
                                )
         SELECT stdlib.current_app_user()
              , CURRENT_USER
              , SESSION_USER
              , classid
              , objid
              , objsubid
              , original
              , normal
              , is_temporary
              , object_type
              , schema_name
              , object_name
              , object_identity
              , address_names
              , address_args
           FROM pg_event_trigger_dropped_objects()
              ;
  END;
$$; COMMENT ON FUNCTION ddl_drop_log() IS
'Debug tracking of DDL DROPs.';

CREATE FUNCTION ddl_log()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
  BEGIN
    INSERT INTO stdlib.ddl_info ( role_name
                                , session_role
                                , classid
                                , objid
                                , objsubid
                                , command_tag
                                , object_type
                                , schema_name
                                , object_identity
                                , in_extension
                                )
         SELECT CURRENT_USER
              , SESSION_USER
              , classid
              , objid
              , objsubid
              , command_tag
              , object_type
              , schema_name
              , object_identity
              , in_extension
           FROM pg_event_trigger_ddl_commands()
              ;
  END;
$$; COMMENT ON FUNCTION ddl_log() IS
'Debug tracking of DDL changes.';

CREATE EVENT TRIGGER _00_ddl_drop
                  ON sql_drop
             EXECUTE PROCEDURE ddl_drop_log()
                   ;

CREATE EVENT TRIGGER _00_ddl_info
                  ON ddl_command_end
             EXECUTE PROCEDURE ddl_log()
                   ;

RESET search_path;

COMMIT;
