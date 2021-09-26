-- Deploy geekspeak:stdlib_aws to pg
-- requires: stdlib_internet

BEGIN;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public;

/*
  See https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-s3-bucket-naming-requirements.html
  for bucket name requirements.
*/
CREATE FUNCTION is_s3_bucket(p_name text)
        RETURNS bool LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
  SELECT p_name ~ '^[a-z0-9][-0-9a-z.]+[0-9a-z.]$' AND NOT p_name ~ '\.-|-\.|\.\.|^\d+\.\d+\.\d+.\d+$'
       ;
$$; COMMENT ON FUNCTION is_s3_bucket(text) IS
'1) Each label in the bucket name must start with a lowercase letter or number.
2) The bucket name can be between 3 and 63 characters long, and can contain
only lower-case characters, numbers, periods, and dashes.
3) The bucket name cannot contain underscores, end with a dash,
have consecutive periods, or use dashes adjacent to periods.
4) The bucket name cannot be formatted as an IP address (198.51.100.24).';

CREATE OR REPLACE FUNCTION is_s3_uri(p_s3_uri text)
                   RETURNS bool LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
  SELECT length(p_s3_uri) <= 1093
         AND (uri_expanded(p_s3_uri)).protocol = 's3'
         AND is_s3_bucket((uri_expanded(p_s3_uri)).hostname)
         AND (uri_expanded(p_s3_uri)).username IS NULL
         AND (uri_expanded(p_s3_uri)).port IS NULL
         AND (uri_expanded(p_s3_uri)).search IS NULL
         AND (uri_expanded(p_s3_uri)).hash IS NULL
       ;
$$; COMMENT ON FUNCTION is_s3_uri(text) IS
'Example: s3://my_bucket/some/file/path/as/an/object/key

Verifies that the string matches a standard URI; that the protocol is "s3";
that there is no query string, hash, user/password, or port; the "hostname"
is a valid bucket name; and that the total length does not exceed Amazon''s
limits for S3 URIs:
       5 chars ("s3://")
  +   63 chars (max bucket name)
  +    1 char ("/" separator)
  + 1024 (max object key)
  ------------------------
  max 1093 chars
';

CREATE DOMAIN s3_bucket
           AS varchar(63)
        CHECK (is_s3_bucket(VALUE))
            ;
COMMENT ON DOMAIN s3_bucket IS
'Accepts valid S3 bucket names.

1) Each label in the bucket name must start with a lowercase letter or number.
2) The bucket name can be between 3 and 63 characters long, and can contain
only lower-case characters, numbers, periods, and dashes.
3) The bucket name cannot contain underscores, end with a dash,
have consecutive periods, or use dashes adjacent to periods.
4) The bucket name cannot be formatted as an IP address (198.51.100.24).';

CREATE DOMAIN s3_uri
           AS varchar(1093)
        CHECK (is_s3_uri(VALUE))
            ;
COMMENT ON DOMAIN s3_bucket IS
'Accepts valid S3 URIs.

Example: s3://my_bucket/some/file/path/as/an/object/key

Verifies that the string matches a standard URI; that the protocol is "s3";
that there is no query string, hash, user/password, or port; the "hostname"
is a valid bucket name; and that the total length does not exceed Amazon''s
limits for S3 URIs:
       5 chars ("s3://")
  +   63 chars (max bucket name)
  +    1 char ("/" separator)
  + 1024 (max object key)
  ------------------------
  max 1093 chars
';

RESET search_path;

COMMIT;