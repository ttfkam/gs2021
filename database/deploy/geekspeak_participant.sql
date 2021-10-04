-- Deploy geekspeak:geekspeak_participant to pg
-- requires: geekspeak_account
-- requires: geekspeak_episode

BEGIN;

-- Everything owned by this user
SET ROLE geekspeak_admin
       ;

CREATE TABLE episode_role ( name text PRIMARY KEY );
COMMENT ON TABLE episode_role IS 'User role in the production of an episode';

CREATE TABLE participant (
            id uuid PRIMARY KEY
               DEFAULT gen_random_uuid()
,   episode_id uuid NOT NULL
               REFERENCES episode
                       ON UPDATE CASCADE
                       ON DELETE CASCADE
,   account_id uuid NOT NULL
               REFERENCES account
                       ON UPDATE CASCADE
                       ON DELETE RESTRICT
, episode_role text NOT NULL
               REFERENCES episode_role
                       ON UPDATE CASCADE
                       ON DELETE RESTRICT
,      created timestamptz NOT NULL
               DEFAULT CURRENT_TIMESTAMP
,       LIKE stdlib.SYSTEM_VERSIONED
             INCLUDING COMMENTS
); COMMENT ON TABLE participant IS
'Accounts associated with an episode';

GRANT SELECT
   ON TABLE episode_role
   TO geekspeak_api
    , geekspeak_user
    ;

GRANT SELECT
    , INSERT
    , UPDATE
    , DELETE
   ON TABLE participant
   TO geekspeak_api
    , geekspeak_user
    ;

RESET ROLE;

COMMIT;
