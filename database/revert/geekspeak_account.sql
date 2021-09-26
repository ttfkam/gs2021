-- Revert geekspeak:geekspeak_account from pg

BEGIN;

-- Everything dropped by this user
SET ROLE geekspeak_admin
       ;

DROP TRIGGER fts_update ON account;

DROP FUNCTION admin_or_same_account()
            , is_admin()
            , fts(account)
            , primary_email(account)
            ;

DROP TABLE account
           CASCADE
         ;

RESET ROLE;

COMMIT;
