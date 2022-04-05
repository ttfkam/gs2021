-- Revert geekspeak:stdlib from pg

BEGIN
;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib
;

DROP FUNCTION set_app_user(text)
            , current_app_user()
            , length_in(text, int4, int4)
            , not_exists(text, text)
;

DROP SCHEMA stdlib
;

COMMIT
;
