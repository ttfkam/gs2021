-- Deploy geekspeak:stdlib to pg

BEGIN;

-- http://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=Example
-- http://patorjk.com/software/taag/#p=display&f=Big&t=Example

--     ██████╗ ██████╗ ███████╗██████╗ ███████╗ ██████╗ ███████╗
--     ██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝██╔═══██╗██╔════╝
--     ██████╔╝██████╔╝█████╗  ██████╔╝█████╗  ██║   ██║███████╗
--     ██╔═══╝ ██╔══██╗██╔══╝  ██╔══██╗██╔══╝  ██║▄▄ ██║╚════██║
--     ██║     ██║  ██║███████╗██║  ██║███████╗╚██████╔╝███████║
--     ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝ ╚══▀▀═╝ ╚══════╝

CREATE SCHEMA stdlib;
 GRANT USAGE
    ON SCHEMA stdlib
    TO public
;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public
;

--    __ _ _ __  _ __    _   _ ___  ___ _ __
--   / _` | '_ \| '_ \  | | | / __|/ _ \ '__|
--  | (_| | |_) | |_) | | |_| \__ \  __/ |
--   \__,_| .__/| .__/   \__,_|___/\___|_|
--        | |   | |
--        |_|   |_|

CREATE FUNCTION set_app_user(p_app_user text)
        RETURNS void LANGUAGE sql VOLATILE AS $$
  SELECT set_config('jwt.claims.email', p_app_user, true)
   WHERE p_app_user IS NOT NULL
  ;

  SELECT NULL::void
  ;
$$; COMMENT ON FUNCTION set_app_user(text) IS
'Sets the current application-level user. This avoids the proliferation of
database cluster roles.'
;

CREATE FUNCTION current_app_user()
        RETURNS text LANGUAGE sql STABLE PARALLEL SAFE AS $$
  SELECT coalesce( nullif( current_setting( 'jwt.claims.email', true), '' )
                 , concat( '%', SESSION_USER, '%' )
                 )
  ;
$$; COMMENT ON FUNCTION current_app_user() IS
'Returns the current application-level user. If there is no app user defined,
return the database cluster role enclosed with ''%'' characters.'
;

--   _                  _   _       _
--  | |                | | | |     (_)
--  | | ___ _ __   __ _| |_| |__    _ _ __
--  | |/ _ \ '_ \ / _` | __| '_ \  | | '_ \
--  | |  __/ | | | (_| | |_| | | | | | | | |
--  |_|\___|_| |_|\__, |\__|_| |_| |_|_| |_|
--                 __/ |       ______
--                |___/       |______|

CREATE FUNCTION length_in(val text, min int4, max int4)
        RETURNS bool LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
    SELECT length(trim(val)) <= max AND length(trim(val)) >= min
    ;
$$;

--               _              _     _
--              | |            (_)   | |
--   _ __   ___ | |_   _____  ___ ___| |_ ___
--  | '_ \ / _ \| __| / _ \ \/ / / __| __/ __|
--  | | | | (_) | |_ |  __/>  <| \__ \ |_\__ \
--  |_| |_|\___/ \__| \___/_/\_\_|___/\__|___/
--                ______
--               |______|

CREATE FUNCTION not_exists( p_type text
                          , p_name text
                          )
        RETURNS bool LANGUAGE plpgsql STRICT STABLE PARALLEL RESTRICTED AS $$
  BEGIN
    IF lower(p_type) = 'domain' OR lower(p_type) = 'type' THEN
      RETURN to_regtype(p_name) IS NULL;
    ELSEIF lower(p_type) = 'function' THEN
      RETURN to_regprocedure(p_name) IS NULL;
    ELSEIF lower(p_type) IN ('role', 'user') THEN
      RETURN to_regrole(p_name) IS NULL;
    ELSEIF lower(p_type) = 'temporary table' THEN
      RETURN NOT EXISTS ( SELECT true
                            FROM pg_class AS c
                           WHERE c.oid = to_regclass(p_name) AND relpersistence = 't'
                        );
    ELSEIF lower(p_type) = 'event trigger' THEN
      RETURN NOT EXISTS ( SELECT true
                            FROM pg_event_trigger
                           WHERE evtname = p_name
                        );
    END IF;
    RETURN false;
  END;
$$; COMMENT ON FUNCTION not_exists(text, text) IS
'Allow idempotent changes to roles, functions, and domains—objects that do not support IF NOT EXISTS.';

RESET search_path;

COMMIT;
