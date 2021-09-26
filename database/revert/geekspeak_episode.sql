-- Revert geekspeak:geekspeak_episode from pg

BEGIN;

-- Everything dropped by this user
SET ROLE geekspeak_admin
       ;

DROP TRIGGER fts_update ON episode
           , fts_update ON geek_bit
           ;

DROP FUNCTION fts(episode)
            , fts(geek_bit)
            ;

DROP TABLE episode
         , episode_status
         , geek_bit
         , geek_bit_status
   CASCADE
         ;

RESET ROLE;

COMMIT;
