-- Revert geekspeak:geekspeak_link from pg

BEGIN;

-- Everything dropped by this user
SET ROLE geekspeak_admin
       ;

DROP FUNCTION fts(link)
      CASCADE
            ;

DROP TABLE link
           CASCADE
         ;

RESET ROLE;

COMMIT;
