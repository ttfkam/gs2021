-- Revert geekspeak:stdlib_country from pg

BEGIN;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib;

DROP TRIGGER generate_postal_code_validator ON country
           ,
           ;

DROP FUNCTION generate_postal_code_validator()
            , is_postal_code(text, varchar)
            , is_postal_code(text, varchar[])
            ;

DROP TABLE country
         ;

RESET search_path;

COMMIT;
