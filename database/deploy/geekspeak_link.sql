-- Deploy geekspeak:geekspeak_link to pg
-- requires: geekspeak_role
-- requires: stdlib_internet
-- requires: stdlib_full_text_search

BEGIN;

-- Everything owned by this user
SET ROLE geekspeak_admin
       ;

CREATE TABLE link (
               id uuid PRIMARY KEY
                  DEFAULT gen_random_uuid()
,             uri stdlib.uri UNIQUE
,           title text
,         summary text
,          scrape text
,        metadata jsonb
,         created timestamptz NOT NULL
                  DEFAULT CURRENT_TIMESTAMP
,            LIKE stdlib.FTS INCLUDING INDEXES
) INHERITS (stdlib.FTS); COMMENT ON TABLE link IS
'External links';
COMMENT ON COLUMN link.scrape   IS 'Scraped text from the link for full text search';
COMMENT ON COLUMN link.metadata IS 'Link metadata such as OpenGraph data';

CREATE FUNCTION fts(rec link)
        RETURNS tsvector LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
    SELECT stdlib.weighted_tsvector(rec.title,   'A')
           || stdlib.weighted_tsvector(rec.summary, 'B')
           || stdlib.weighted_tsvector(rec.scrape,  'D')
           ;
$$;

CREATE TRIGGER fts_update
        BEFORE INSERT OR UPDATE
            ON link
      FOR EACH ROW
       EXECUTE PROCEDURE stdlib.fts_trigger()
             ;

 GRANT SELECT
     , INSERT
     , UPDATE
     , DELETE
    ON TABLE link
    TO geekspeak_app
     ;

 GRANT SELECT
    ON TABLE link
    TO geekspeak_analysis
     ;

RESET ROLE;

COMMIT;
