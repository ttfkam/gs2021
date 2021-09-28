-- Deploy geekspeak:stdlib_full_text_search to pg
-- requires: stdlib

BEGIN;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib;

CREATE TABLE FTS (
           id uuid
, _stdlib_fts tsvector
);

CREATE FUNCTION search( IN  p_query tsquery
                      , OUT id      uuid
                      , OUT relinfo regclass
                      , OUT rank    float4
                      )
        RETURNS SETOF RECORD LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $$
  SELECT id
       , tableoid::regclass
       , ts_rank_cd(_stdlib_fts, p_query) rank
    FROM FTS
   WHERE p_query @@ _stdlib_fts
   ORDER BY rank DESC
       ;
$$;

CREATE FUNCTION search( IN  p_query text
                      , OUT id      uuid
                      , OUT relinfo regclass
                      , OUT rank    float4
                      )
        RETURNS SETOF RECORD LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $$
  SELECT id
       , relinfo
       , rank
    FROM search(websearch_to_tsquery('english', p_query))
       ;
$$;

CREATE FUNCTION weighted_tsvector(field text, weight "char" = 'D')
        RETURNS tsvector LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
    SELECT setweight(to_tsvector('english', coalesce(field, '')), weight)
         ;
$$;

CREATE FUNCTION fts(FTS)
        RETURNS tsvector LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $$
  SELECT NULL::tsvector
       ;
$$; COMMENT ON FUNCTION fts(FTS) IS
'Placeholder for full text search vector creation';

CREATE FUNCTION fts_trigger()
        RETURNS trigger LANGUAGE plpgsql AS $$
  BEGIN
    NEW._stdlib_fts := fts(NEW);
    return NEW;
  END
$$;

RESET search_path;

COMMIT;
