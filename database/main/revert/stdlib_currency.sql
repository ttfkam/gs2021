-- Revert geekspeak:stdlib_currency from pg

BEGIN
;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib
;

DROP TABLE currency
   CASCADE
;

RESET search_path
;

COMMIT
;
