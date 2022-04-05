-- Revert geekspeak:stdlib_common_id from pg

BEGIN
;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib
;

DROP FUNCTION gen_test_uuid()
;

DROP SEQUENCE lookup_id_seq
            , id_seq
            , test_id_seq
;

RESET search_path
;

COMMIT
;
