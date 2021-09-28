-- Revert geekspeak:geekspeak_episode_asset from pg

BEGIN;

-- Everything dropped by this user
SET ROLE geekspeak_admin
       ;

DROP TRIGGER fts_update ON episode_asset
           ;

DROP FUNCTION fts(episode_asset)
            ;

DROP TABLE episode_asset
         , __episode_asset__
   CASCADE
         ;

RESET ROLE;

COMMIT;
