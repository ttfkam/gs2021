-- Deploy geekspeak:geekspeak_episode_asset to pg
-- requires: geekspeak_episode

BEGIN;

-- Everything owned by this user
SET ROLE geekspeak_admin
       ;

CREATE TABLE episode_asset (
           id uuid PRIMARY KEY
,  episode_id uuid
              REFERENCES episode
                      ON UPDATE CASCADE
                      ON DELETE SET NULL
,    filename text NOT NULL
, description text
,  media_type text NOT NULL
,    metadata jsonb
,     created timestamptz NOT NULL
              DEFAULT CURRENT_TIMESTAMP
,        LIKE stdlib.SYSTEM_VERSIONED
              INCLUDING COMMENTS
,        LIKE stdlib.FTS
              INCLUDING COMMENTS
              INCLUDING INDEXES
,      UNIQUE (episode_id, filename)
); COMMENT ON TABLE episode_asset IS
'External files associated with an episode like images and other media';
COMMENT ON COLUMN episode_asset.filename IS 'Human-readable file name';
COMMENT ON COLUMN episode_asset.metadata IS 'Asset metadata such as found in EXIF data or ID3v2';

CREATE FUNCTION fts(rec episode_asset)
        RETURNS tsvector LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
    SELECT    stdlib.weighted_tsvector(rec.filename   , 'B')
           || stdlib.weighted_tsvector(rec.description, 'C')
           ;
$$;

CREATE TRIGGER fts_update
        BEFORE INSERT OR UPDATE
            ON episode_asset
      FOR EACH ROW
       EXECUTE PROCEDURE stdlib.fts_trigger()
             ;

 GRANT SELECT
    ON TABLE episode_asset
    TO geekspeak_api
     , geekspeak_analysis
     ;

 GRANT SELECT
     , INSERT
     , UPDATE
     , DELETE
    ON TABLE episode_asset
    TO geekspeak_user
     ;

RESET ROLE;

COMMIT;
