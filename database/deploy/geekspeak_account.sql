-- Deploy geekspeak:geekspeak_account to pg
-- requires: geekspeak_role
-- requires: stdlib_internet
-- requires: stdlib_full_text_search

BEGIN;

-- Everything owned by this user
SET ROLE geekspeak_admin
       ;

CREATE TABLE account (
               id uuid PRIMARY KEY
                  DEFAULT gen_random_uuid()
,          emails stdlib.email[] NOT NULL
                  CHECK (array_length(emails, 1) > 0)
,            name text NOT NULL
                  CHECK (length(trim(name)) > 0)
,             bio text
,           roles text[]
,         created timestamptz NOT NULL
                  DEFAULT CURRENT_TIMESTAMP
,            LIKE stdlib.FTS INCLUDING INDEXES
,         EXCLUDE USING gist (emails WITH &&)
) INHERITS (stdlib.SYSTEM_VERSIONED, stdlib.FTS);
COMMENT ON  TABLE account        IS 'User accounts';
COMMENT ON COLUMN account.emails IS 'Email address(es) linked to this account';
COMMENT ON COLUMN account.name   IS 'Account''s name to be displayed';
COMMENT ON COLUMN account.bio    IS 'Account holder''s short biography';
COMMENT ON COLUMN account.roles  IS 'Roles within the application, eg. admin, geek, guest';

CREATE FUNCTION primary_email(a account)
        RETURNS text LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
    SELECT a.emails[1];
$$; COMMENT ON FUNCTION primary_email(account) IS
'The primary email address for the account';

--    __ _  ___ ___ ___  ___ ___
--   / _` |/ __/ __/ _ \/ __/ __|
--  | (_| | (_| (_|  __/\__ \__ \
--   \__,_|\___\___\___||___/___/  _   _
--                | |      (_)    | | (_)
--   _ __ ___  ___| |_ _ __ _  ___| |_ _  ___  _ __  ___
--  | '__/ _ \/ __| __| '__| |/ __| __| |/ _ \| '_ \/ __|
--  | | |  __/\__ \ |_| |  | | (__| |_| | (_) | | | \__ \
--  |_|  \___||___/\__|_|  |_|\___|\__|_|\___/|_| |_|___/

ALTER TABLE account
     ENABLE ROW LEVEL SECURITY
          ;

CREATE FUNCTION admin_or_same_account(emails text[])
        RETURNS boolean LANGUAGE sql STABLE PARALLEL SAFE AS $$
    SELECT is_admin()
           OR ARRAY[current_setting('jwt.claims.email', true)] <@ emails
         ;
$$;

CREATE FUNCTION is_admin()
        RETURNS boolean LANGUAGE sql STABLE PARALLEL SAFE AS $$
    SELECT nullif(current_setting('jwt.claims.admin', true), '')::boolean
         ;
$$;

CREATE POLICY account_select
           ON account
          FOR SELECT
           TO geekspeak_app
        USING (true) -- Anyone can view
            ;

CREATE POLICY account_insert
           ON account
          FOR INSERT
           TO geekspeak_app
        USING (is_admin())
   WITH CHECK (is_admin())
            ;

CREATE POLICY account_update
           ON account
          FOR UPDATE
           TO geekspeak_app
        USING (admin_or_same_account(emails))
   WITH CHECK (admin_or_same_account(emails))
            ;

CREATE FUNCTION fts(a account)
        RETURNS tsvector LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
    SELECT stdlib.weighted_tsvector(new.name, 'A')
           || stdlib.weighted_tsvector(new.bio, 'B')
         ;
$$;

CREATE TRIGGER fts_update
        BEFORE INSERT OR UPDATE
            ON account
      FOR EACH ROW
       EXECUTE PROCEDURE stdlib.fts_trigger()
             ;

 GRANT SELECT
     , INSERT
     , UPDATE
     , DELETE
    ON TABLE account
    TO geekspeak_app
     ;

 GRANT SELECT
    ON TABLE account
    TO geekspeak_analysis
     ;

RESET ROLE;

COMMIT;
