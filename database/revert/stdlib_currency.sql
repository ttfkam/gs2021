-- Revert geekspeak:stdlib_currency from pg

BEGIN;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib;

DROP TABLE currency
         , __currency__
   CASCADE
         ;

RESET search_path;

COMMIT;
