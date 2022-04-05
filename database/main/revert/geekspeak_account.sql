-- Revert geekspeak:geekspeak_account from pg

BEGIN
;

-- Everything dropped by this user
SET ROLE geekspeak_admin
;

DROP FUNCTION fts( account )
;

DROP TABLE account
         , account_email
   CASCADE
;

DROP FUNCTION admin_or_same_account( uuid )
            , is_admin()
;

RESET ROLE
;

COMMIT
;
