-- Deploy geekspeak:geekspeak_episode_asset to pg
-- requires: geekspeak_episode

BEGIN;

-- Everything owned by this user
SET ROLE geekspeak_admin
       ;

CREATE TABLE episode_asset (
 episode_asset_id uuid PRIMARY KEY
,      episode_id uuid
                  REFERENCES episode
                          ON UPDATE CASCADE
                          ON DELETE SET NULL
,        filename text NOT NULL
,     description text
,      media_type text NOT NULL
,        metadata jsonb
,         created timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
) INHERITS (stdlib.FTS, stdlib.SYSTEM_VERSIONED); COMMENT ON TABLE episode_asset IS
'External files associated with an episode like images and other media';
COMMENT ON COLUMN episode_asset.filename IS 'Human-readable file name';
COMMENT ON COLUMN episode_asset.metadata IS 'Asset metadata such as found in EXIF data or ID3v2';

CREATE INDEX episode_asset_stdlib_fts_idx
          ON episode_asset
       USING GIN (_stdlib_fts)
           ;

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

RESET ROLE;

COMMIT;
