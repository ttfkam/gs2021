-- Revert geekspeak:geekspeak_participant from pg

BEGIN
;

-- Everything dropped by this user
SET ROLE geekspeak_admin
;

DROP TABLE episode_role
         , participant
   CASCADE
;

RESET ROLE
;

COMMIT
;
