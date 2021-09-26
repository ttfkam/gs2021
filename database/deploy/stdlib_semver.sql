-- Deploy geekspeak:stdlib_semver to pg
-- requires: stdlib

BEGIN;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public;

CREATE FUNCTION semver_expanded( IN  p_version      text
                               , OUT version        text
                               , OUT major          int2
                               , OUT minor          int2
                               , OUT patch          int2
                               , OUT prerelease     text
                               , OUT build_metadata text
                               )
        RETURNS record LANGUAGE sql STRICT IMMUTABLE PARALLEL RESTRICTED AS $$
  WITH ver AS (
    SELECT regexp_match( p_version
                         -- From https://regex101.com/r/vkijKf/1/ via https://semver.org/
                       , '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
                       ) parts
  )
  SELECT p_version
       , ver.parts[1]::int2
       , ver.parts[2]::int2
       , ver.parts[3]::int2
       , ver.parts[4]
       , ver.parts[5]
    FROM ver
   WHERE ver.parts IS NOT NULL
       ;
$$;

CREATE DOMAIN semver AS text CHECK (NOT semver_expanded(VALUE) IS NULL)
COMMENT ON DOMAIN semver IS 'Semantic version number.';

RESET search_path;

COMMIT;
