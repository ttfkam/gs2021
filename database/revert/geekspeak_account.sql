-- Revert geekspeak:geekspeak_account from pg

BEGIN;

-- Everything dropped by this user
SET ROLE geekspeak_admin
       ;

DROP FUNCTION admin_or_same_account(uuid)
            , is_admin()
            , fts(account)
      CASCADE
            ;

DROP TABLE
 IF EXISTS account
         , account_email
   CASCADE
         ;

RESET ROLE;

COMMIT;
