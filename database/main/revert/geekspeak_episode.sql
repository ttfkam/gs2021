-- Revert geekspeak:geekspeak_episode from pg

BEGIN;

-- Everything dropped by this user
SET ROLE geekspeak_admin
       ;

DROP FUNCTION fts(episode)
            , fts(geek_bit)
      CASCADE
            ;

DROP TABLE
 IF EXISTS episode
         , geek_bit
         , episode_status
         , geek_bit_status
   CASCADE
         ;

RESET ROLE;

COMMIT;
