-- Revert geekspeak:stdlib_country from pg

BEGIN
;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib
;

DROP FUNCTION is_postal_code(text, varchar)
            , is_postal_code(text, varchar[])
;

DROP TABLE country
   CASCADE
;

RESET search_path
;

COMMIT
;
