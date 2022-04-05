-- Deploy geekspeak:geekspeak_episode to pg
-- requires: geekspeak_link
-- requires: stdlib_config_system_versioning

BEGIN
;

-- Everything owned by this user
SET ROLE geekspeak_admin
;

CREATE TABLE episode_status ( name text PRIMARY KEY );

CREATE TABLE episode (
          id uuid PRIMARY KEY
             DEFAULT gen_random_uuid()
,      title text UNIQUE
,      promo text
,    summary text
,     status text NOT NULL
             REFERENCES episode_status
                     ON UPDATE CASCADE
                     ON DELETE RESTRICT
,    airdate date
,       body text
,  bit_order uuid[]
,    publish timestamptz
,    created timestamptz NOT NULL
             DEFAULT CURRENT_TIMESTAMP
,       LIKE stdlib.SYSTEM_VERSIONED
             INCLUDING COMMENTS
,       LIKE stdlib.FTS
             INCLUDING COMMENTS
             INCLUDING INDEXES
); COMMENT ON TABLE episode IS
'Episodes of GeekSpeak';
COMMENT ON COLUMN episode.promo     IS 'Episode promotional text';
COMMENT ON COLUMN episode.airdate   IS 'When the episode was made available';
COMMENT ON COLUMN episode.body      IS 'Episode content';
COMMENT ON COLUMN episode.bit_order IS 'Order that bits appear on the episode page';
COMMENT ON COLUMN episode.publish   IS 'When the episode is to be made visible';
CREATE INDEX episode_airdate_idx
          ON episode
       USING BTREE (airdate)
;
CREATE INDEX episode_publish_idx
          ON episode
       USING BTREE (publish)
;
CREATE INDEX episode_status_idx
          ON episode
       USING BTREE (status)
;

CREATE TABLE IF NOT EXISTS geek_bit_status ( name text PRIMARY KEY );

CREATE TABLE IF NOT EXISTS geek_bit (
               id uuid PRIMARY KEY
                  DEFAULT gen_random_uuid()
,         link_id uuid
                  REFERENCES link
                          ON UPDATE CASCADE
                          ON DELETE RESTRICT
,      episode_id uuid
                  REFERENCES episode
                          ON UPDATE CASCADE
                          ON DELETE SET NULL
,       offset_ms int4
,           title text
,          status text NOT NULL
                  REFERENCES geek_bit_status
                          ON UPDATE CASCADE
                          ON DELETE RESTRICT
,            body text
,         created timestamptz NOT NULL
                  DEFAULT CURRENT_TIMESTAMP
,            LIKE stdlib.SYSTEM_VERSIONED
                  INCLUDING COMMENTS
,            LIKE stdlib.FTS
                  INCLUDING COMMENTS
                  INCLUDING INDEXES
,          UNIQUE ( episode_id
                  , link_id
                  )
); COMMENT ON TABLE geek_bit IS
'Geek bits';
COMMENT ON COLUMN geek_bit.offset_ms IS 'Time offset where the geek_bit exists in the episode';
COMMENT ON COLUMN geek_bit.body      IS 'Bit content';

CREATE INDEX geek_bit_link_id_idx
          ON geek_bit
       USING BTREE (link_id)
;
CREATE INDEX geek_bit_episode_id_idx
          ON geek_bit
       USING BTREE (episode_id)
;
CREATE INDEX geek_bit_status_idx
          ON geek_bit
       USING BTREE (status)
;

CREATE FUNCTION episodes_by_airdate(p_start date, p_end date)
        RETURNS SETOF episode LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $$
    SELECT e.*
      FROM episode e
     WHERE e.airdate >= p_start
           AND e.airdate < p_end
    ;
$$; COMMENT ON FUNCTION episodes_by_airdate(date, date) IS
'Retrive all episodes from a date range. Note: end date is exclusive.';

CREATE FUNCTION fts(rec episode)
        RETURNS tsvector LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
    SELECT    stdlib.weighted_tsvector(rec.title  , 'A')
           || stdlib.weighted_tsvector(rec.promo  , 'B')
           || stdlib.weighted_tsvector(rec.summary, 'B')
           || stdlib.weighted_tsvector(rec.body   , 'C')
    ;
$$;

CREATE FUNCTION fts(rec geek_bit)
        RETURNS tsvector LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
    SELECT    stdlib.weighted_tsvector(rec.title, 'A')
           || stdlib.weighted_tsvector(rec.body , 'B')
    ;
$$;

CREATE TRIGGER fts_update
        BEFORE INSERT OR UPDATE
            ON episode
      FOR EACH ROW
       EXECUTE PROCEDURE stdlib.fts_trigger()
;

CREATE TRIGGER fts_update
        BEFORE INSERT OR UPDATE
            ON geek_bit
      FOR EACH ROW
       EXECUTE PROCEDURE stdlib.fts_trigger()
;

GRANT SELECT
   ON TABLE episode
          , geek_bit
          , episode_status
          , geek_bit_status
   TO geekspeak_api
    , geekspeak_analysis
;

GRANT SELECT
    , INSERT
    , UPDATE
    , DELETE
   ON TABLE episode
          , geek_bit
          , episode_status
          , geek_bit_status
   TO geekspeak_user
;

RESET ROLE
;

COMMIT
;
