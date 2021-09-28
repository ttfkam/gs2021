-- Revert geekspeak:geekspeak_account from pg

BEGIN;

-- Everything dropped by this user
SET ROLE geekspeak_admin
       ;

DROP TRIGGER fts_update ON account;

DROP FUNCTION admin_or_same_account(uuid)
            , is_admin()
            , fts(account)
            ;

DROP TABLE account
         , account_email
         , __account__
         , __account_email__
   CASCADE
         ;

RESET ROLE;

COMMIT;
