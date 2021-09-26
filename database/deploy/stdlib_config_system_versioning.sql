-- Deploy geekspeak:stdlib_config_system_versioning to pg
-- requires: stdlib

BEGIN;

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

CREATE TABLE NOT_SYSTEM_VERSIONED ();
COMMENT ON TABLE NOT_SYSTEM_VERSIONED IS
'@omit
When inherited, prevents the system from automatically making a system versioned
history for that table.';

CREATE TABLE SYSTEM_VERSIONED ();
COMMENT ON TABLE SYSTEM_VERSIONED IS
'@omit
Generic system versioned metadata to track changes by user, transaction, and/or timestamp.
By inheriting from this table, an event trigger will handle details.';

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

CREATE FUNCTION current_system_versioned()
        RETURNS __system_versioned LANGUAGE sql STRICT VOLATILE PARALLEL RESTRICTED AS $$
  SELECT txid_current()
       , tstzrange(clock_timestamp(), NULL, '[)')
       , current_app_user()
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
    NEW._system := current_system_versioned();
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
    NEW._system := current_system_versioned();
    RETURN NEW;
  END;
$$; COMMENT ON FUNCTION system_versioned_update() IS
'Updates system versioned metadata automatically on system versioned tables.';

CREATE FUNCTION system_versioned_update_to_history()
        RETURNS trigger LANGUAGE plpgsql AS $$
  BEGIN
    -- Set an end timestamp to the system versioned row before recording in history
    OLD._system := system_versioned_close(OLD._system, lower((NEW._system).system_time));
    EXECUTE format( 'INSERT INTO %1$I.__%2$I__
                          SELECT *
                            FROM jsonb_populate_recordset( NULL::%1$I.__%2$I__
                                                         , %3$L::jsonb
                                                         );
                    '
                  , TG_TABLE_SCHEMA
                  , TG_TABLE_NAME
                  , concat('[', row_to_json(OLD)::text, ']')
                  );
    -- This is for an AFTER trigger, so the event has already occurred.
    -- Returning NULL has no effect.
    RETURN NULL;
  END;
$$; COMMENT ON FUNCTION system_versioned_update_to_history() IS
'Records updates to system versioned tables to their respective history tables.';

CREATE FUNCTION system_versioned_delete_to_history()
        RETURNS trigger LANGUAGE plpgsql AS $$
  DECLARE
       json_row text;
    this_moment timestamptz = clock_timestamp();
          query text        =
                'INSERT INTO %1$I.__%2$I__
                      SELECT *
                        FROM jsonb_populate_recordset( NULL::%1$I.__%2$I__
                                                     , %3$L::jsonb
                                                     )
                           ;';
  BEGIN
    -- Set an end timestamp to the system versioned row before recording in history
    OLD._system := system_versioned_close(OLD._system, this_moment);
    EXECUTE format( query
                  , TG_TABLE_SCHEMA
                  , TG_TABLE_NAME
                  , concat( '[', row_to_json(OLD)::text, ']' )
                  );

    -- Set an end timestamp to the system versioned row before recording in history
    OLD._system = ( txid_current()
                  , tstzrange(this_moment, this_moment, '[]')
                  , current_app_user()
                  );
    -- Insert the delete action
    EXECUTE format( query
                  , TG_TABLE_SCHEMA
                  , TG_TABLE_NAME
                  , concat('[', row_to_json(OLD)::text, ']')
                  );
    -- This is for an AFTER trigger, so the event has already occurred.
    -- Returning NULL has no effect.
    RETURN NULL;
  END;
$$; COMMENT ON FUNCTION system_versioned_delete_to_history() IS
'Records deletes from system versioned tables to their respective history tables.';

CREATE FUNCTION system_versioned_truncate_to_history()
        RETURNS trigger LANGUAGE plpgsql AS $$
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
                     INSERT INTO %1$I.__%2$I__
                          SELECT r.*
                            FROM ended AS e
                      CROSS JOIN LATERAL jsonb_populate_record( NULL::%1$I.__%2$I__
                                                              , e.payload
                                                              )
                                 AS r
                               ;'
                  , TG_TABLE_SCHEMA
                  , TG_TABLE_NAME
                  );
    RETURN null;
  END;
$$; COMMENT ON FUNCTION system_versioned_truncate_to_history() IS
'Records bulk deletes on system versioned tables.';

CREATE FUNCTION is_history_attached(p_table text)
        RETURNS bool LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $$
  SELECT COUNT(inh.*) = 1
    FROM pg_inherits AS inh
    JOIN pg_class    AS rel
         ON ( inh.inhrelid = rel.oid )
    JOIN pg_class    AS history
         ON ( inh.inhparent = history.oid
              AND rel.relnamespace = history.relnamespace
              AND history.relname = concat('__', rel.relname, '__')
            )
   WHERE inh.inhrelid = to_regclass(p_table)
       ;
$$; COMMENT ON FUNCTION is_history_attached(text) IS
'Whether a table is system versioned, has a history table, and is currently linked to
that history.';

CREATE FUNCTION last_modified(p_system __system_versioned)
        RETURNS timestamptz LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
  SELECT lower(p_system.system_time)
       ;
$$;

CREATE FUNCTION init_system_versioned_history( p_schema_name name
                                                        , p_table_name name
                                                        )
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE PARALLEL UNSAFE AS $$
  DECLARE
    history_name name := concat('__', p_table_name, '__');
  BEGIN
    EXECUTE format(
      '-- Creating history table
       CREATE TABLE IF NOT EXISTS %1$I.%3$I AS
             SELECT x.*
                  , NULL::__system_versioned AS _system
               FROM %1$I.%2$I AS x
            WITH NO DATA
                  ;
       COMMENT ON TABLE %1$I.%3$I IS
       E''@omit\nAuto-generated history for table %1$I.%2$I.\nNot included in the GraphQL schema.'';

       REVOKE ALL PRIVILEGES
           ON %1$I.%3$I
         FROM PUBLIC
            ; -- on the history table

       -- Only allow insert and select to the history; make it immutable
       GRANT SELECT
           , INSERT
          ON %1$I.%3$I
          TO PUBLIC
           ;

       ALTER TABLE IF EXISTS %1$I.%2$I
               ADD COLUMN IF NOT EXISTS _system __system_versioned NOT NULL,
           INHERIT %1$I.%3$I
                 ;
       -- Prevent the system versioned column from being altered through GraphQL
       COMMENT ON COLUMN %1$I.%2$I._system IS
       E''@omit create,update,delete\nAuto-generated system versioned data for table %1$I.%2$I.'';

       CREATE FUNCTION %1$I.%2$I(tstzrange)
               RETURNS SETOF %1$I.%3$I LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $system_versioned$
         SELECT *
           FROM %1$I.%3$I
          WHERE (_system).system_time && $1
              ;
       $system_versioned$; COMMENT ON FUNCTION %1$I.%2$I(tstzrange) IS
       E''Auto-generated\nAllow easy searching of %1$I.%2$I history by timestamp range'';

       CREATE FUNCTION %1$I.%2$I(timestamptz)
               RETURNS SETOF %1$I.%3$I LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $system_versioned$
         SELECT *
           FROM %1$I.%2$I( tstzrange( $1, $1, ''[]'' ) )
              ;
       $system_versioned$; COMMENT ON FUNCTION %1$I.%2$I(timestamptz) IS
       E''Auto-generated\nPoint in time accessor for %1$I.%2$I'';

       CREATE FUNCTION last_modified(rec %1$I.%2$I)
               RETURNS timestamptz LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
         SELECT lower((rec._system).system_time);
       $$;

       CREATE FUNCTION last_modified_by(rec %1$I.%2$I)
               RETURNS text LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
         SELECT (rec._system).username;
       $$;

       DROP TRIGGER IF EXISTS system_versioned_insert_trigger      ON %1$I.%2$I;
       DROP TRIGGER IF EXISTS system_versioned_update_trigger      ON %1$I.%2$I;
       DROP TRIGGER IF EXISTS system_versioned_update_to_history   ON %1$I.%2$I;
       DROP TRIGGER IF EXISTS system_versioned_delete_to_history   ON %1$I.%2$I;
       DROP TRIGGER IF EXISTS system_versioned_truncate_to_history ON %1$I.%2$I;

       CREATE TRIGGER system_versioned_insert_trigger
               BEFORE INSERT
                   ON %1$I.%2$I
             FOR EACH ROW
              EXECUTE PROCEDURE system_versioned_insert()
                    ; COMMENT ON TRIGGER system_versioned_insert_trigger ON %1$I.%2$I IS
       E''Auto-generated\nEnsures system versioned data is automatically generated, not user-supplied'';

       CREATE TRIGGER system_versioned_update_trigger
               BEFORE UPDATE
                   ON %1$I.%2$I
             FOR EACH ROW
              EXECUTE PROCEDURE system_versioned_update()
                    ; COMMENT ON TRIGGER system_versioned_update_trigger ON %1$I.%2$I IS
       E''Auto-generated\nMake sure system versioned data is updated in the live table'';

       CREATE TRIGGER system_versioned_update_to_history
                AFTER UPDATE
                   ON %1$I.%2$I
             FOR EACH ROW
              EXECUTE PROCEDURE system_versioned_update_to_history()
                    ; COMMENT ON TRIGGER system_versioned_update_to_history ON %1$I.%2$I IS
       E''Auto-generated\nAdd entry pre-update to the history and make sure system versioned data is coherent'';

       CREATE TRIGGER system_versioned_delete_to_history
                AFTER DELETE
                   ON %1$I.%2$I
             FOR EACH ROW
              EXECUTE PROCEDURE system_versioned_delete_to_history()
                    ; COMMENT ON TRIGGER system_versioned_delete_to_history ON %1$I.%2$I IS
       E''Auto-generated\nAdd deleted entry to the history and make sure system versioned data is coherent'';

       CREATE TRIGGER system_versioned_truncate_to_history
               BEFORE TRUNCATE
                   ON %1$I.%2$I
             FOR EACH STATEMENT
              EXECUTE PROCEDURE system_versioned_truncate_to_history()
                    ; COMMENT ON TRIGGER system_versioned_truncate_to_history ON %1$I.%2$I IS
       E''Auto-generated\nAdd truncated entries to the history and make sure system versioned data is coherent'';
    ', p_schema_name, p_table_name, history_name);
  END;
$$; COMMENT ON FUNCTION init_system_versioned_history(name, name) IS
'Create a system versioned history table, link to active table, and set up access triggers.';

CREATE FUNCTION disable_system_versioned_history( p_schema_name name
                                                           , p_table_name name
                                                           )
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE PARALLEL UNSAFE AS $$
  DECLARE
    history_name name = concat( '__', p_table_name, '__' );
  BEGIN
    EXECUTE format( 'ALTER TABLE IF EXISTS %1$I.%2$I
                        NO INHERIT %1$I.%3$I
                         ;

                     DROP FUNCTION IF EXISTS %1$I.%2$I(tstzrange)
                                           , %1$I.%2$I(timestamptz)
                                           ;

                     -- Keep the insert and update triggers by default
                     DROP TRIGGER IF EXISTS system_versioned_update_to_history   ON %1$I.%2$I;
                     DROP TRIGGER IF EXISTS system_versioned_delete_to_history   ON %1$I.%2$I;
                     DROP TRIGGER IF EXISTS system_versioned_truncate_to_history ON %1$I.%2$I;'
                  , p_schema_name
                  , p_table_name
                  , history_name
                  );
  END;
$$; COMMENT ON FUNCTION disable_system_versioned_history(name, name) IS
'Unlink a system versioned history table from its active table.';

CREATE FUNCTION deny_invalid_system_versioned_create()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
  DECLARE
    r record;
  BEGIN
    FOR r IN
      SELECT d.object_identity
        FROM pg_event_trigger_ddl_commands() AS d
        JOIN pg_class    AS c     ON (d.objid = c.oid          AND NOT c.relhassubclass)
        JOIN pg_inherits AS tem   ON (d.objid = tem.inhrelid   AND tem.inhparent   = 'SYSTEM_VERSIONED'::regclass)
        JOIN pg_inherits AS notem ON (d.objid = notem.inhrelid AND notem.inhparent = 'NOT_SYSTEM_VERSIONED'::regclass)
    LOOP
      RAISE EXCEPTION 'Table % cannot inherit from both SYSTEM_VERSIONED and NOT_SYSTEM_VERSIONED'
                    , r.object_identity
                    ;
    END LOOP;
  END;
$$; COMMENT ON FUNCTION deny_invalid_system_versioned_create() IS
'Prevent contradictory system versioned table tags.';

CREATE FUNCTION default_system_versioned_create()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
  DECLARE
    r record;
  BEGIN
    IF NOT get_config( 'system versioned tables by default', false ) THEN
      RETURN;
    END IF;

    FOR r IN
      SELECT DISTINCT
             c.relnamespace::regnamespace::name AS schema_name
           , c.relname                          AS table_name
        FROM pg_event_trigger_ddl_commands() AS d
        JOIN pg_class                        AS c
             ON ( d.objid = c.oid
                  AND c.relkind = 'r'
                  AND NOT c.relhassubclass
                )
        LEFT JOIN pg_inherits                AS temporal
             ON ( d.objid = temporal.inhrelid
                  AND temporal.inhparent = 'SYSTEM_VERSIONED'::regclass
                )
        LEFT JOIN pg_inherits                AS notem
             ON ( d.objid = notem.inhrelid
                  AND notem.inhparent = 'NOT_SYSTEM_VERSIONED'::regclass
                )
       -- Don't ever apply this to internal tables (prefixed with underscore(s))
       WHERE c.relname !~ '^__'
             AND c.relnamespace::regnamespace::name <> 'stdlib'
             AND tem.inhrelid IS NULL
             AND notem.inhrelid IS NULL
    LOOP
      RAISE INFO 'System versioned tables by default is enabled. Adding system versioned flag to %.%'
               , r.schema_name
               , r.table_name
               ;
      EXECUTE format( 'ALTER TABLE %1$I.%2$I INHERIT SYSTEM_VERSIONED;'
                    , r.schema_name
                    , r.table_name
                    );
    END LOOP;
  END;
$$; COMMENT ON FUNCTION default_system_versioned_create() IS
'Adds table metadata when the setting "system versioned tables by default" is set to true.';

CREATE FUNCTION create_system_versioned_history()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
  DECLARE
    r record;
    columns record;
  BEGIN
    FOR r IN
      SELECT DISTINCT
             c.relnamespace::regnamespace::name AS schema_name
           , c.relname                          AS table_name
        FROM pg_event_trigger_ddl_commands() AS d
        JOIN pg_class                        AS c
             ON (d.objid = c.oid)
        JOIN pg_inherits                     AS i
             ON ( d.objid = i.inhrelid
                  AND i.inhparent = 'system_versioned'::regclass
                )
        LEFT JOIN pg_class                   AS history
             ON ( c.relnamespace = history.relnamespace
                  AND history.relname = concat('__', c.relname, '__')
                )
       WHERE c.relname !~ '^_'
             AND c.relkind = 'r'
             AND NOT c.relhassubclass
             AND history.oid IS NULL
    LOOP
      RAISE INFO 'Enabling system versioned history for table: %.%'
               , r.schema_name
               , r.table_name
               ;
      PERFORM init_system_versioned_history( r.schema_name, r.table_name );
    END LOOP;
  END;
$$; COMMENT ON FUNCTION create_system_versioned_history() IS
'Sets up history table, accessor functions, and relevant triggers for system versioned
tables.';

CREATE FUNCTION alter_system_versioned_history()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
  DECLARE
    r record;
    column_ddl text;
  BEGIN
    FOR r IN
      SELECT DISTINCT
             c.relnamespace::regnamespace::name AS schema_name
           , c.relname                          AS table_name
           , inh.inhrelid IS NOT NULL           AS is_system_versioned
           , history.relname                    AS history_name
           , hist_inh.inhrelid IS NOT NULL      AS attached_to_history
        FROM pg_event_trigger_ddl_commands() AS d
        JOIN pg_class                        AS c
             ON ( d.objid = c.oid
                  AND NOT c.relhassubclass
                  AND c.relkind = 'r'
                  AND c.relname !~ '^_'
                )
        LEFT JOIN pg_inherits                AS inh
             ON ( d.objid = inh.inhrelid
                  AND inh.inhparent = to_regclass('SYSTEM_VERSIONED')
                )
        LEFT JOIN pg_class                   AS history
             ON ( history.relnamespace = r.schema
                  AND history.relname = concat('__', c.relname, '__')
                )
        LEFT JOIN pg_inherits                AS hist_inh
             ON ( d.objid = inh.inhrelid
                  AND inh.inhparent = history.oid
                )
    LOOP
      IF NOT r.is_system_versioned AND r.history_name IS NULL THEN
        -- Nothing to do since not system versioned and no history table; in other words
        -- the table has never been system versioned.
        CONTINUE;
      ELSEIF r.is_system_versioned AND r.history_name IS NULL THEN
        -- Add history et al.
        PERFORM init_system_versioned_history(r.schema_name, r.table_name);
      ELSEIF NOT r.is_system_versioned AND r.attached_to_history THEN
        -- Detach from history and disable the auditing to history
        EXECUTE format( 'ALTER TABLE IF EXISTS %1$I.%2$I
                                  NO INHERIT %1$I.%3$I
                                   ;
                         DROP FUNCTION IF EXISTS %1$I.%2$I(tstzrange)
                                               , %1$I.%2$I(timestamptz)
                                               ;
                         DROP TRIGGER IF EXISTS system_versioned_update_to_history   ON %1$I.%2$I
                                              , system_versioned_delete_to_history   ON %1$I.%2$I
                                              , system_versioned_truncate_to_history ON %1$I.%2$I
                                              ;'
                      , r.schema_name
                      , r.table_name
                      , r.history_name
                      );
      ELSEIF r.is_system_versioned THEN
        -- Check for difference in columns
        WITH active AS (
          SELECT a.*
            FROM pg_attribute AS a
           WHERE a.attrelid = to_regclass( concat( quote_ident( r.schema_name )
                                                 , '.'
                                                 , quote_ident( r.table_name )
                                                 )
                                         )
                 AND a.attnum > 0
                 AND NOT a.attisdropped
        ), history AS (
          SELECT a.*
            FROM pg_attribute AS a
           WHERE a.attrelid = to_regclass( quote_ident( r.schema_name )
                                           || '.'
                                           || quote_ident( r.history_name )
                                         )
                 AND a.attnum > 0
                 AND NOT a.attisdropped
        )
        SELECT string_agg( CASE WHEN active.atttypid IS NULL THEN
                                'DROP COLUMN IF EXISTS ' || history.attname
                           WHEN history.atttypid IS NULL THEN
                                'ADD COLUMN IF NOT EXISTS '
                                || active.attname
                                || ' '
                                || to_regtype(active.atttypid)
                           ELSE NULL
                           END
                         , E'\n              '
                         ) FILTER ( WHERE active.atttypid IS NOT NULL
                                          AND history.atttypid IS NOT NULL
                                  )
          INTO column_ddl
          FROM active
          FULL JOIN history ON (active.attname = history.attname)
         WHERE active.atttypid IS DISTINCT FROM history.atttypid
      ORDER BY active.attnum
             , history.attnum
             ;

        IF column_ddl IS NOT NULL THEN
            EXECUTE format( 'ALTER TABLE IF EXISTS %1$I.%2$I %3$s;'
                          , r.schema_name
                          , r.history_name
                          , column_ddl
                          );
        END IF;

        IF NOT r.attached_to_history THEN
          -- Attach to history and restore triggers
          PERFORM init_system_versioned_history(r.schema_name, r.table_name);
        END IF;
      END IF;
    END LOOP;
  END;
$$; COMMENT ON FUNCTION alter_system_versioned_history() IS
'Sets up history table, accessor functions, and relevant triggers for system versioned
tables.';

CREATE FUNCTION disable_system_versioned_history()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
  DECLARE
    r record;
  BEGIN
    FOR r IN
      SELECT c.relnamespace::regnamespace::name AS schema
           , c.relname                          AS table_name
        FROM pg_event_trigger_ddl_commands() AS d
        JOIN pg_class      AS c
             ON (d.objid = c.oid AND NOT c.relhassubclass)
        LEFT JOIN pg_class AS history
             ON ( c.relnamespace = history.relnamespace
                  AND history.relname = ('__' || c.relname || '__')
                )
        JOIN pg_attribute  AS a
             ON ( d.objid = a.attrelid
                  AND a.attname = '_system'
                )
        JOIN pg_inherits   AS h
             ON ( d.objid = h.inhrelid
                  AND h.inhparent = history.oid
                )
        LEFT JOIN pg_inherits AS i
             ON ( d.objid = i.inhrelid
                  AND i.inhparent = 'SYSTEM_VERSIONED'::regclass
                )
      -- Don't ever apply this to internal tables (prefixed with underscore(s))
      WHERE c.relname !~ '^_'
            AND i.inhparent IS NULL -- The SYSTEM_VERSIONED table has been de-inherited
    LOOP
      RAISE INFO 'Detaching system versioned history from table: %.%'
               , r.schema_name
               , r.table_name
               ;
      PERFORM disable_system_versioned_history(r.schema, r.table_name);
      RAISE WARNING 'System versioned history detached from table %.% but system_versioned_insert_trigger, system_versioned_update_trigger, and the history table must be removed manually.'
                  , r.schema
                  , r.table_name
                  ;
    END LOOP;
  END;
$$; COMMENT ON FUNCTION disable_system_versioned_history() IS
'Disables (but does not remove) history, accessor functions, and history
persistence triggers for former system versioned tables.';

-- Triggers are executed in alphabetical order, so make system versioned creation run
-- after any other custom triggers that could alter table structure run.
CREATE EVENT TRIGGER _50_deny_invalid_system_versioned_create ON ddl_command_end
                WHEN TAG IN ('CREATE TABLE', 'ALTER TABLE')
             EXECUTE PROCEDURE deny_invalid_system_versioned_create()
                   ;

CREATE EVENT TRIGGER _51_default_system_versioned_create ON ddl_command_end
                WHEN TAG IN ('CREATE TABLE', 'ALTER TABLE')
             EXECUTE PROCEDURE default_system_versioned_create()
                   ;

CREATE EVENT TRIGGER _52_create_system_versioned_history ON ddl_command_end
                WHEN TAG IN ('CREATE TABLE')
             EXECUTE PROCEDURE create_system_versioned_history()
                   ;

CREATE EVENT TRIGGER _53_disable_system_versioned_history ON ddl_command_end
                WHEN TAG IN ('ALTER TABLE')
             EXECUTE PROCEDURE disable_system_versioned_history()
                   ;

CREATE EVENT TRIGGER _54_alter_system_versioned_history ON ddl_command_end
                WHEN TAG IN ('ALTER TABLE')
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
) INHERITS (SYSTEM_VERSIONED); COMMENT ON TABLE config IS
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
                         CASE WHEN arr.username !~ '^%.+%$' THEN current_app_user() = arr.username
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
    FROM config AS c
   WHERE c.option_name = p_name
       ;
$$; COMMENT ON FUNCTION get_config(text) IS
'@omit
Returns a config value, subject to row-level restrictions. Prefer the versions
of get_config(...) that take a default value.';

CREATE FUNCTION get_config(p_name text, p_default text)
        RETURNS text LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT coalesce( get_config( p_name ), p_default )
       ;
$$; COMMENT ON FUNCTION get_config(text, text) IS
'@ignore-lint FUNCTION_IMMUTABLE calls config(text)';

CREATE FUNCTION get_config(p_name text, p_default int8)
        RETURNS int8 LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT coalesce( get_config( p_name )::int8, p_default )
       ;
$$; COMMENT ON FUNCTION get_config(text, int8) IS
'@ignore-lint FUNCTION_IMMUTABLE calls config(text)';

CREATE FUNCTION get_config(p_name text, p_default float8)
        RETURNS float8 LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT coalesce( get_config( p_name )::float8, p_default )
       ;
$$; COMMENT ON FUNCTION get_config(text, float8) IS
'@ignore-lint FUNCTION_IMMUTABLE calls config(text)';

CREATE FUNCTION get_config(p_name text, p_default bool)
        RETURNS bool LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT coalesce( get_config( p_name )::bool, p_default )
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
  SELECT set_config( p_name
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
  SELECT set_config( p_name
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
  SELECT set_config( p_name
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
