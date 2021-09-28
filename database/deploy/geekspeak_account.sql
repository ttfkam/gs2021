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
,            name text NOT NULL
                  CHECK (length(trim(name)) > 0)
,             bio text
,           roles text[]
,         created timestamptz NOT NULL
                  DEFAULT CURRENT_TIMESTAMP
) INHERITS (stdlib.SYSTEM_VERSIONED, stdlib.FTS);
COMMENT ON  TABLE account        IS 'User accounts';
COMMENT ON COLUMN account.name   IS 'Account''s name to be displayed';
COMMENT ON COLUMN account.bio    IS 'Account holder''s short biography';
COMMENT ON COLUMN account.roles  IS 'Roles within the application, eg. admin, geek, guest';

CREATE INDEX account_stdlib_fts_idx
          ON account
       USING GIN (_stdlib_fts)
           ;

CREATE TABLE account_email (
       email stdlib.email PRIMARY KEY
, account_id uuid NOT NULL
             REFERENCES account
                     ON UPDATE CASCADE
                     ON DELETE CASCADE
);

CREATE INDEX account_id_idx
          ON account_email
       USING BTREE (account_id)
           ;

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

CREATE FUNCTION is_admin()
        RETURNS boolean LANGUAGE sql STABLE PARALLEL SAFE AS $$
    SELECT nullif(current_setting('jwt.claims.admin', true), '')::boolean
         ;
$$;

CREATE FUNCTION admin_or_same_account(p_id uuid)
        RETURNS boolean LANGUAGE sql STABLE PARALLEL SAFE AS $$
    SELECT bool_or(current_setting('jwt.claims.email', true) = e.email)
      FROM account_email e
     WHERE is_admin()
           OR p_id = e.account_id
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
   WITH CHECK (is_admin())
            ;

CREATE POLICY account_update
           ON account
          FOR UPDATE
           TO geekspeak_app
        USING (admin_or_same_account(id))
   WITH CHECK (admin_or_same_account(id))
            ;

CREATE POLICY account_delete
           ON account
          FOR DELETE
           TO geekspeak_app
        USING (admin_or_same_account(id))
            ;

CREATE FUNCTION fts(a account)
        RETURNS tsvector LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
    SELECT stdlib.weighted_tsvector(a.name, 'A')
           || stdlib.weighted_tsvector(a.bio, 'B')
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
