-- Revert geekspeak:stdlib_aws from pg

BEGIN
;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib
;

DROP DOMAIN s3_bucket
          , s3_uri
;

DROP FUNCTION is_s3_bucket( text )
            , is_s3_uri( text )
;

RESET search_path
;

COMMIT
;
