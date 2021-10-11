-- Deploy geekspeak:stdlib_config_system_versioning to pg
-- requires: stdlib

BEGIN;

CREATE SCHEMA system_versioning
            ;
 GRANT USAGE
    ON SCHEMA system_versioning
    TO public
     ;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public;

-- Placeholder stub since system versioned support depends on config and config
-- depends on system versioned support.
CREATE FUNCTION get_config( p_name text
                          , p_default bool
                          )
        RETURNS bool LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT true;
$$;

--    ████████╗███████╗███╗   ███╗██████╗  ██████╗ ██████╗  █████╗ ██╗
--    ╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██║
--       ██║   █████╗  ██╔████╔██║██████╔╝██║   ██║██████╔╝███████║██║
--       ██║   ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██║   ██║██╔══██╗██╔══██║██║
--       ██║   ███████╗██║ ╚═╝ ██║██║     ╚██████╔╝██║  ██║██║  ██║███████╗
--       ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
--         ███████╗██╗   ██╗██████╗ ██████╗  ██████╗ ██████╗ ████████╗
--         ██╔════╝██║   ██║██╔══██╗██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝
--         ███████╗██║   ██║██████╔╝██████╔╝██║   ██║██████╔╝   ██║
--         ╚════██║██║   ██║██╔═══╝ ██╔═══╝ ██║   ██║██╔══██╗   ██║
--         ███████║╚██████╔╝██║     ██║     ╚██████╔╝██║  ██║   ██║
--         ╚══════╝ ╚═════╝ ╚═╝     ╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝

CREATE TABLE __system_versioned (
  transaction_id int8 NOT NULL,
     system_time tstzrange NOT NULL,
        username text NOT NULL
); COMMENT ON TABLE __system_versioned IS
'@omit
Generic system versioned metadata to track changes by user, transaction, and/or timestamp.
All values are considered read-only once they reach the system versioned history.

Notes:
  * See documentation on generating uuid
    https://dba.stackexchange.com/questions/122623/default-value-for-uuid-column-in-postgres#122624
  * See documentation on ranges
    https://www.postgresql.org/docs/10/static/rangetypes.html
    https://www.postgresql.org/docs/10/static/functions-range.html

Example SQL:
  * to get value from range
    SELECT lower(_system.system_time), upper(_system.system_time)
    FROM system_versioned_entity;
  * to get active data at a specific time.
    SELECT *
    FROM system_versioned_entity
    WHERE _system.system_time @> ''2014-08-08''::timestamptz;
  * to get active data right now.
    SELECT *
    FROM system_versioned_entity
    WHERE _system.system_time @> NOW();';
COMMENT ON COLUMN __system_versioned.username IS
'User/role who created the system versioned record.';
COMMENT ON COLUMN __system_versioned.transaction_id IS
'Transaction ID.';
COMMENT ON COLUMN __system_versioned.system_time IS
'The time range the entity is active for. An entity will always start being
active at the time it was inserted.';

CREATE TABLE SYSTEM_VERSIONED (
  _system __system_versioned NOT NULL
);
COMMENT ON TABLE SYSTEM_VERSIONED IS
'@omit
Generic system versioned metadata to track changes by user, transaction, and/or timestamp.
By inheriting from this table, an event trigger will handle details.';

CREATE VIEW table_history AS
     SELECT live.oid::regclass live
          , history.relname    history
       FROM pg_inherits inh
       JOIN pg_class    live    ON (inh.inhrelid  = live.oid)
       JOIN pg_class    history ON (inh.inhparent = history.oid)
      WHERE history.relnamespace = 'system_versioning'::regnamespace
          ;

GRANT SELECT
   ON TABLE __system_versioned
          , SYSTEM_VERSIONED
          , table_history
   TO public
    ;

CREATE FUNCTION current_system_versioned()
        RETURNS __system_versioned LANGUAGE sql STRICT VOLATILE PARALLEL RESTRICTED AS $$
  SELECT txid_current()
       , tstzrange(clock_timestamp(), NULL, '[)')
       , stdlib.current_app_user()
       ;
$$; COMMENT ON FUNCTION current_system_versioned() IS
'@omit
Used to populate default system versioned metadata on insert.';

CREATE FUNCTION system_versioned_close( p_system_versioned __system_versioned
                                      , p_end timestamptz
                                      )
        RETURNS __system_versioned LANGUAGE sql STRICT IMMUTABLE PARALLEL RESTRICTED AS $$
  SELECT p_system_versioned.transaction_id
       , tstzrange(lower(p_system_versioned.system_time), p_end, '[)')
       , p_system_versioned.username
       ;
$$; COMMENT ON FUNCTION system_versioned_close(__system_versioned, timestamptz) IS
'@omit
Convenience function to update system versioned metadata.';

CREATE FUNCTION system_versioned_insert()
        RETURNS trigger LANGUAGE plpgsql AS $$
  BEGIN
    NEW._system := stdlib.current_system_versioned();
    RETURN NEW;
  END;
$$; COMMENT ON FUNCTION system_versioned_insert() IS
'User-space must never enter system versioned info. This guarantees auto-gen.';

CREATE FUNCTION system_versioned_update()
        RETURNS trigger LANGUAGE plpgsql AS $$
  BEGIN
    IF (get_config('write when unchanged', false)
        AND (to_jsonb(OLD) - '_system') = (to_jsonb(NEW) - '_system')) THEN
      RETURN NULL; -- Nothing new to write, so save some I/O
    END IF;
    NEW._system := stdlib.current_system_versioned();
    RETURN NEW;
  END;
$$; COMMENT ON FUNCTION system_versioned_update() IS
'Updates system versioned metadata automatically on system versioned tables.';

CREATE FUNCTION system_versioned_update_to_history()
        RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
  BEGIN
    -- Set an end timestamp to the system versioned row before recording in history
    OLD._system := stdlib.system_versioned_close(OLD._system, lower((NEW._system).system_time));
    EXECUTE format( 'INSERT INTO system_versioning.%1$I
                          SELECT *
                            FROM jsonb_populate_recordset( NULL::system_versioning.%1$I
                                                         , %2$L::jsonb
                                                         )
                               ;
                    '
                  , TG_ARGV[0]
                  , concat('[', row_to_json(OLD)::text, ']')
                  );
    -- This is for an AFTER trigger, so the event has already occurred.
    -- Returning NULL has no effect.
    RETURN NULL;
  END;
$$; COMMENT ON FUNCTION system_versioned_update_to_history() IS
'Records updates to system versioned tables to their respective history tables.';

CREATE FUNCTION system_versioned_delete_to_history()
        RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
  DECLARE
       json_row text;
    this_moment timestamptz = clock_timestamp();
          query text        =
                'INSERT INTO system_versioning.%1$I
                      SELECT *
                        FROM jsonb_populate_recordset( NULL::system_versioning.%1$I
                                                     , %3$L::jsonb
                                                     )
                           ;';
  BEGIN
    -- Set an end timestamp to the system versioned row before recording in history
    OLD._system := stdlib.system_versioned_close(OLD._system, this_moment);
    EXECUTE format( query
                  , TG_ARGV[0]
                  , concat( '[', row_to_json(OLD)::text, ']' )
                  );

    -- Set an end timestamp to the system versioned row before recording in history
    OLD._system = ( txid_current()
                  , tstzrange(this_moment, this_moment, '[]')
                  , stdlib.current_app_user()
                  );
    -- Insert the delete action
    EXECUTE format( query
                  , TG_ARGV[0]
                  , concat('[', row_to_json(OLD)::text, ']')
                  );
    -- This is for an AFTER trigger, so the event has already occurred.
    -- Returning NULL has no effect.
    RETURN NULL;
  END;
$$; COMMENT ON FUNCTION system_versioned_delete_to_history() IS
'Records deletes from system versioned tables to their respective history tables.';

CREATE FUNCTION system_versioned_truncate_to_history()
        RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
  BEGIN
    -- Set all of the end timestamps and send to history in one shot.
    EXECUTE format( 'WITH ended AS (
                       SELECT jsonb_set( to_jsonb(x)
                                       , ''{_system,system_time}''
                                       , to_jsonb( tstzrange( lower((x._system).system_time)
                                                            , clock_timestamp()
                                                            , ''[)''
                                                            )
                                                 )
                                       )
                              AS payload
                         FROM %1$I.%2$I AS x
                     )
                     INSERT INTO system_versioning.%3$I
                          SELECT r.*
                            FROM ended AS e
                      CROSS JOIN LATERAL jsonb_populate_record( NULL::system_versioning.%3$I
                                                              , e.payload
                                                              )
                                 AS r
                               ;'
                  , TG_TABLE_SCHEMA
                  , TG_TABLE_NAME
                  , TG_ARGV[0]
                  );
    RETURN null;
  END;
$$; COMMENT ON FUNCTION system_versioned_truncate_to_history() IS
'Records bulk deletes on system versioned tables.';

CREATE FUNCTION is_history_attached(p_table text)
        RETURNS bool LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $$
  SELECT COUNT(th.*) = 1
    FROM stdlib.table_history th
   WHERE th.live = to_regclass(p_table)
       ;
$$; COMMENT ON FUNCTION is_history_attached(text) IS
'Whether a table is system versioned, has a history table, and is currently linked to
that history.';

CREATE FUNCTION make_history_dependent( p_live    regclass
                                      , p_history regclass
                                      )
        RETURNS void LANGUAGE sql STRICT VOLATILE SECURITY DEFINER AS $$
  INSERT INTO pg_depend ( classid
                        , objid
                        , objsubid
                        , refclassid
                        , refobjid
                        , refobjsubid
                        , deptype
                        )
       SELECT 'pg_class'::regclass
            , p_history
            , 0
            , 'pg_class'::regclass
            , p_live
            , 0
            , 'n'
         FROM pg_class c
        WHERE c.oid = p_history
              AND c.relnamespace = 'system_versioning'::regnamespace
            ;
$$;

CREATE FUNCTION grant_access_to_history( IN       p_live_table regclass
                                       , VARIADIC p_roles      regrole[]
                                       )
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE AS $$
  BEGIN
    EXECUTE format(
      '
        GRANT SELECT
           ON TABLE %1$s
           TO %2$s
            ;
      '
    , (SELECT history::text FROM table_history WHERE live = p_live_table)
    ,  array_to_string(p_roles::text[], ', ')
    );
  END;
$$;

CREATE FUNCTION revoke_access_from_history( IN       p_live_table regclass
                                          , VARIADIC p_roles      regrole[]
                                          )
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE AS $$
  BEGIN
    EXECUTE format(
      '
        REVOKE SELECT
            ON TABLE %1$s
          FROM %2$s
             ;
      '
    , (SELECT history::text FROM table_history WHERE live = p_live_table)
    ,  array_to_string(p_roles::text[], ', ')
    );
  END;
$$;

CREATE FUNCTION init_system_versioned_history( p_schema_name name
                                             , p_table_name name
                                             , p_history_name name
                                             )
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE PARALLEL UNSAFE AS $$
  BEGIN
    EXECUTE format(
      '-- Creating history table
       CREATE TABLE IF NOT EXISTS system_versioning.%3$I (
                             LIKE %1$I.%2$I
                                  INCLUDING COMMENTS
       ); COMMENT ON TABLE system_versioning.%3$I IS
       E''@omit\nAuto-generated history for table %1$I.%2$I.\nNot included in the GraphQL schema.'';

       REVOKE ALL PRIVILEGES
           ON system_versioning.%3$I
         FROM PUBLIC
            ; -- on the history table

       ALTER TABLE IF EXISTS %1$I.%2$I
           INHERIT system_versioning.%3$I
                 ;
       -- Prevent the system versioned column from being altered through GraphQL
       COMMENT ON COLUMN %1$I.%2$I._system IS
       E''@omit\nAuto-generated system versioned data for table %1$I.%2$I.'';

       -- Allow histories to cascade when dropping their live tables
       SELECT stdlib.make_history_dependent( ''%1$I.%2$I''::regclass
                                           , ''system_versioning.%3$I''::regclass
                                           );

       CREATE OR REPLACE FUNCTION %1$I.%2$I(tstzrange)
                          RETURNS SETOF system_versioning.%3$I LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $system_versioned$
         SELECT *
           FROM system_versioning.%3$I
          WHERE (_system).system_time && $1
              ;
       $system_versioned$; COMMENT ON FUNCTION %1$I.%2$I(tstzrange) IS
       E''Allow easy searching of %1$I.%2$I history by timestamp range'';

       CREATE OR REPLACE FUNCTION %1$I.%2$I(timestamptz)
                          RETURNS SETOF system_versioning.%3$I LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $system_versioned$
         SELECT *
           FROM %1$I.%2$I( tstzrange( $1, $1, ''[]'' ) )
              ;
       $system_versioned$; COMMENT ON FUNCTION %1$I.%2$I(timestamptz) IS
       E''Point in time accessor for %1$I.%2$I'';

       CREATE OR REPLACE FUNCTION %1$I."%2$s_history"(rec %1$I.%2$I)
                          RETURNS SETOF system_versioning.%3$I LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $system_versioned$
         SELECT *
           FROM system_versioning.%3$I
              ;
       $system_versioned$; COMMENT ON FUNCTION %1$I."%2$s_history"(rec %1$I.%2$I) IS
       E''Row history for %1$I.%2$I'';

       CREATE OR REPLACE FUNCTION %1$I."%2$s_last_modified"(rec %1$I.%2$I)
                          RETURNS timestamptz LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $system_versioned$
         SELECT lower((rec._system).system_time);
       $system_versioned$; COMMENT ON FUNCTION %1$I."%2$s_last_modified"(%1$I.%2$I) IS
       E''Row last modified for %1$I.%2$I'';

       CREATE OR REPLACE FUNCTION %1$I."%2$s_last_modified_by"(rec %1$I.%2$I)
                          RETURNS text LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $system_versioned$
         SELECT (rec._system).username;
       $system_versioned$; COMMENT ON FUNCTION %1$I."%2$s_last_modified_by"(%1$I.%2$I) IS
       E''User who last modified the row in %1$I.%2$I'';

       CREATE TRIGGER system_versioned_insert_trigger
               BEFORE INSERT
                   ON %1$I.%2$I
             FOR EACH ROW
              EXECUTE PROCEDURE stdlib.system_versioned_insert()
                    ; COMMENT ON TRIGGER system_versioned_insert_trigger ON %1$I.%2$I IS
       E''Auto-generated\nEnsures system versioned data is automatically generated, not user-supplied'';

       CREATE TRIGGER system_versioned_update_trigger
               BEFORE UPDATE
                   ON %1$I.%2$I
             FOR EACH ROW
              EXECUTE PROCEDURE stdlib.system_versioned_update()
                    ; COMMENT ON TRIGGER system_versioned_update_trigger ON %1$I.%2$I IS
       E''Auto-generated\nMake sure system versioned data is updated in the live table'';

       CREATE TRIGGER system_versioned_update_to_history
                AFTER UPDATE
                   ON %1$I.%2$I
             FOR EACH ROW
              EXECUTE PROCEDURE stdlib.system_versioned_update_to_history(%3$L)
                    ; COMMENT ON TRIGGER system_versioned_update_to_history ON %1$I.%2$I IS
       E''Auto-generated\nAdd entry pre-update to the history and make sure system versioned data is coherent'';

       CREATE TRIGGER system_versioned_delete_to_history
                AFTER DELETE
                   ON %1$I.%2$I
             FOR EACH ROW
              EXECUTE PROCEDURE stdlib.system_versioned_delete_to_history(%3$L)
                    ; COMMENT ON TRIGGER system_versioned_delete_to_history ON %1$I.%2$I IS
       E''Auto-generated\nAdd deleted entry to the history and make sure system versioned data is coherent'';

       CREATE TRIGGER system_versioned_truncate_to_history
               BEFORE TRUNCATE
                   ON %1$I.%2$I
             FOR EACH STATEMENT
              EXECUTE PROCEDURE stdlib.system_versioned_truncate_to_history(%3$L)
                    ; COMMENT ON TRIGGER system_versioned_truncate_to_history ON %1$I.%2$I IS
       E''Auto-generated\nAdd truncated entries to the history and make sure system versioned data is coherent'';
    ', p_schema_name, p_table_name, p_history_name);
  END;
$$; COMMENT ON FUNCTION init_system_versioned_history(name, name, name) IS
'Create a system versioned history table, link to active table, and set up access triggers.';

CREATE FUNCTION drop_history(VARIADIC p_tables regclass[])
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE AS $$
  DECLARE
    r record;
  BEGIN
    FOR r IN
      SELECT
    DISTINCT th.live
           , th.history
        FROM stdlib.table_history th
        JOIN unnest(p_tables) live(ref)
             ON (th.live = live.ref)
    LOOP
      EXECUTE format(
        '
          DROP TABLE system_versioning.%2$I
             CASCADE
                   ;
        ', live::text, history);
    END LOOP;
  END;
$$;

CREATE FUNCTION create_system_versioned_history()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
  DECLARE
    r record;
    columns record;
  BEGIN
    FOR r IN
      SELECT c.relnamespace::regnamespace::name                   AS schema_name
           , c.relname                                            AS table_name
           , (gen_random_uuid()::text  || '_' || c.relname)::name AS history_name
        FROM pg_event_trigger_ddl_commands() AS d
        JOIN pg_attribute                    AS a
             ON ( d.objid = a.attrelid
                  AND a.attname = '_system'
                )
        JOIN pg_class                        AS c
             ON ( d.objid = c.oid )
        LEFT JOIN stdlib.table_history       AS th
             ON ( d.objid = th.live )
       WHERE c.relnamespace <> 'system_versioning'::regnamespace
             AND th.history IS NULL -- Don't add history where it already exists
       LIMIT 1
    LOOP
      PERFORM stdlib.init_system_versioned_history( r.schema_name
                                                  , r.table_name
                                                  , r.history_name
                                                  )
            ;
    END LOOP;
  END;
$$; COMMENT ON FUNCTION create_system_versioned_history() IS
'Sets up history table, accessor functions, and relevant triggers for system versioned
tables.';

CREATE EVENT TRIGGER _52_create_system_versioned_history ON ddl_command_end
                WHEN TAG IN ('CREATE TABLE')
             EXECUTE PROCEDURE create_system_versioned_history()
                   ;

--      ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗
--     ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝
--     ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
--     ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
--     ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
--      ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝

DO $$ BEGIN IF not_exists('role', 'stdlib_config_admin') THEN

  CREATE ROLE stdlib_config_admin;

END IF; END; $$ LANGUAGE plpgsql;

CREATE TABLE config (
   option_name text PRIMARY KEY
               CHECK (length_in(option_name, 1, 126))
, option_value text NOT NULL
               CHECK (length_in(option_value, 1, 2047))
,  read_access name[]
, write_access name[]
,         LIKE stdlib.SYSTEM_VERSIONED
               INCLUDING COMMENTS
); COMMENT ON TABLE config IS
'Database app-level configuration.';
COMMENT ON COLUMN config.option_name  IS 'Config key.';
COMMENT ON COLUMN config.option_value IS 'Config value.';
COMMENT ON COLUMN config.read_access  IS
'Row-level access to read this config value. An array of role names. An empty
array means no access is granted (except to superusers and roles that
explicitly bypass row-level security policies). A NULL value allows all users
to access.';
COMMENT ON COLUMN config.write_access IS
'Row-level access to write to this config value. An array of role names. An
empty array means updates/deletes are denied (except to superusers and roles
that explicitly bypass row-level security policies). A NULL value allows all
users to update/delete.';

 ALTER TABLE config
       ENABLE ROW LEVEL SECURITY
     ;

REVOKE ALL
    ON TABLE config
  FROM public
     ;

 GRANT SELECT ( option_name, option_value )
    ON TABLE config
    TO public
     ;

 GRANT ALL
    ON TABLE config
    TO stdlib_config_admin
     ;

CREATE POLICY public_access
    ON config
   FOR SELECT
    TO public
 USING ( read_access IS NULL
         OR (
              SELECT coalesce(
                       bool_or(
                         -- If it's from 'app.user', just do a simple match
                         CASE WHEN arr.username !~ '^%.+%$' THEN stdlib.current_app_user() = arr.username
                              -- If it looks like '%username%', strip the bounding percents and do
                              -- a role check, including inherited roles.
                              ELSE pg_has_role( CURRENT_USER
                                                , regexp_replace(arr.username, '^%|%$', '')
                                                , 'MEMBER, USAGE'
                                                )
                         END
                       )
                     , false
                     )
                FROM unnest(read_access) arr(username)
            )
       )
       ;

CREATE POLICY admin_access
           ON config
          FOR ALL
           TO stdlib_config_admin
        USING ( true )
            ;

-- Set some default config options, readable by anyone but can only be changed
-- by a superuser.
INSERT INTO config ( option_name
                   , option_value
                   , read_access
                   , write_access
                   )
     VALUES ( 'system versioned tables by default', false, NULL, '{}' )
          , ( 'table upsert by default',            false, NULL, '{}' )
         ON CONFLICT (option_name)
         DO NOTHING
          ;

CREATE FUNCTION get_config(p_name text)
        RETURNS text LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT c.option_value
    FROM stdlib.config c
   WHERE c.option_name = p_name
       ;
$$; COMMENT ON FUNCTION get_config(text) IS
'@omit
Returns a config value, subject to row-level restrictions. Prefer the versions
of get_config(...) that take a default value.';

CREATE FUNCTION get_config(p_name text, p_default text)
        RETURNS text LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT coalesce( stdlib.get_config( p_name ), p_default )
       ;
$$; COMMENT ON FUNCTION get_config(text, text) IS
'@ignore-lint FUNCTION_IMMUTABLE calls config(text)';

CREATE FUNCTION get_config(p_name text, p_default int8)
        RETURNS int8 LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT coalesce( stdlib.get_config( p_name )::int8, p_default )
       ;
$$; COMMENT ON FUNCTION get_config(text, int8) IS
'@ignore-lint FUNCTION_IMMUTABLE calls config(text)';

CREATE FUNCTION get_config(p_name text, p_default float8)
        RETURNS float8 LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT coalesce( stdlib.get_config( p_name )::float8, p_default )
       ;
$$; COMMENT ON FUNCTION get_config(text, float8) IS
'@ignore-lint FUNCTION_IMMUTABLE calls config(text)';

DROP FUNCTION get_config(text, bool);
CREATE FUNCTION stdlib.get_config(p_name text, p_default bool)
        RETURNS bool LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT coalesce( stdlib.get_config( p_name )::bool, p_default )
       ;
$$; COMMENT ON FUNCTION get_config(text, bool) IS
'@ignore-lint FUNCTION_IMMUTABLE calls config(text)';

CREATE FUNCTION set_config( p_name        text
                                     , p_value       text
                                     , p_read_roles  name[] = NULL
                                     , p_write_roles name[] = '{}'
                                     )
        RETURNS text LANGUAGE sql VOLATILE PARALLEL UNSAFE AS $$
  INSERT INTO config ( option_name
                     , option_value
                     , read_access
                     , write_access
                     )
       VALUES ( p_name, p_value, p_read_roles, p_write_roles )
           ON CONFLICT ( option_name )
           DO UPDATE SET
              option_value = p_value
            , read_access  = p_read_roles
            , write_access = p_write_roles
    RETURNING option_value
            ;
$$; COMMENT ON FUNCTION set_config(text, text, name[], name[]) IS
'Sets a text config value, subject to row-level restrictions.';

CREATE FUNCTION set_config( p_name        text
                                     , p_value       int8
                                     , p_read_roles  name[] = NULL
                                     , p_write_roles name[] = '{}'
                                     )
        RETURNS int8 LANGUAGE sql VOLATILE PARALLEL UNSAFE AS $$
  SELECT stdlib.set_config( p_name
                          , p_value::text
                          , p_read_roles
                          , p_write_roles
                          )::int8
       ;
$$; COMMENT ON FUNCTION set_config(text, int8, name[], name[]) IS
'@ignore-lint FUNCTION_IMMUTABLE calls set_config(text, text, name[], name[])
Sets a 64-bit integer config value, subject to row-level restrictions.';

CREATE FUNCTION set_config( p_name        text
                                     , p_value       float8
                                     , p_read_roles  name[] = NULL
                                     , p_write_roles name[] = '{}'
                                     )
        RETURNS float8 LANGUAGE sql VOLATILE PARALLEL UNSAFE AS $$
  SELECT stdlib.set_config( p_name
                          , p_value::text
                          , p_read_roles
                          , p_write_roles
                          )::float8
       ;
$$; COMMENT ON FUNCTION set_config(text, float8, name[], name[]) IS
'@ignore-lint FUNCTION_IMMUTABLE calls set_config(text, text, name[], name[])
Sets a 64-bit floating point config value, subject to row-level restrictions.';

CREATE FUNCTION set_config( p_name        text
                                     , p_value       bool
                                     , p_read_roles  name[] = NULL
                                     , p_write_roles name[] = '{}'
                                     )
        RETURNS bool LANGUAGE sql VOLATILE PARALLEL UNSAFE AS $$
  SELECT stdlib.set_config( p_name
                          , p_value::text
                          , p_read_roles
                          , p_write_roles
                          )::bool
       ;
$$; COMMENT ON FUNCTION set_config(text, bool, name[], name[]) IS
'@ignore-lint FUNCTION_IMMUTABLE calls set_config(text, text, name[], name[])
Sets a bool config value, subject to row-level restrictions.';

REVOKE ALL
    ON FUNCTION set_config( text, text, name[], name[] )
  FROM public
     ;
 GRANT EXECUTE
    ON FUNCTION set_config( text, text, name[], name[] )
    TO stdlib_config_admin
     ;

REVOKE ALL
    ON FUNCTION set_config( text, int8, name[], name[] )
  FROM public
     ;
 GRANT EXECUTE
    ON FUNCTION set_config( text, int8, name[], name[] )
    TO stdlib_config_admin
     ;

REVOKE ALL
    ON FUNCTION set_config( text, float8, name[], name[] )
  FROM public
     ;
 GRANT EXECUTE
    ON FUNCTION set_config( text, float8, name[], name[] )
    TO stdlib_config_admin
     ;

REVOKE ALL
    ON FUNCTION set_config( text, bool, name[], name[] )
  FROM public
     ;
 GRANT EXECUTE
    ON FUNCTION set_config( text, bool, name[], name[] )
    TO stdlib_config_admin
     ;

RESET search_path;

COMMIT;
