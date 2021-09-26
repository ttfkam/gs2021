-- Revert geekspeak:stdlib_semver from pg

BEGIN;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib;

DROP DOMAIN semver
          ;

DROP FUNCTION semver_expanded(text)
            ;

RESET search_path;

COMMIT;
