-- Revert geekspeak:geekspeak_link from pg

BEGIN;

-- Everything dropped by this user
SET ROLE geekspeak_admin
       ;

DROP TRIGGER fts_update ON link
           ;

DROP FUNCTION fts(link)
            ;

DROP TABLE link
           CASCADE
         ;

RESET ROLE;

COMMIT;
