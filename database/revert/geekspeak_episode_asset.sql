-- Revert geekspeak:geekspeak_episode_asset from pg

BEGIN;

-- Everything dropped by this user
SET ROLE geekspeak_admin
       ;

DROP FUNCTION fts(episode_asset)
      CASCADE
            ;

DROP TABLE
 IF EXISTS episode_asset
         , __episode_asset__
   CASCADE
         ;

RESET ROLE;

COMMIT;
