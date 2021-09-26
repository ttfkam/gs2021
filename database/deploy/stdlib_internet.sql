-- Deploy geekspeak:stdlib_internet to pg
-- requires: stdlib

BEGIN;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public;

--                      _ _         _
--                     | (_)       | |
--   _ __ ___   ___  __| |_  __ _  | |_ _   _ _ __   ___
--  | '_ ` _ \ / _ \/ _` | |/ _` | | __| | | | '_ \ / _ \
--  | | | | | |  __/ (_| | | (_| | | |_| |_| | |_) |  __/
--  |_| |_| |_|\___|\__,_|_|\__,_|  \__|\__, | .__/ \___|
--                                       __/ | |
--                                      |___/|_|

CREATE FUNCTION jsonb_media_type_parameters(p_parameters text)
        RETURNS jsonb LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
  SELECT jsonb_object_agg( split_part( params.param, '=', 1 )
                         , split_part( params.param, '=', 2 )
                         )
    FROM unnest( array_remove( regexp_split_to_array( p_parameters, ';\s?' )
                             , '' -- removing empty strings from the array
                             )
               ) AS params( param )
       ;
$$; COMMENT ON FUNCTION jsonb_media_type_parameters(text) IS
'Parse the key-value pairs from media type parameters into JSON.';

CREATE FUNCTION media_type( IN  p_media_type      text
                          , OUT media_type        text
                          , OUT type              text
                          , OUT registration_tree text
                          , OUT subtype           text
                          , OUT suffix            text
                          , OUT parameters        text
                          , OUT jsonb_parameters  jsonb
                          , OUT category          varchar(1)
                          )
        RETURNS record LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
  WITH matched AS (
    SELECT regexp_match( p_media_type
                       , concat(
                           -- type
                           '^(application|audio|font|image|message|model|multipart|text|video)'
                           -- type separator
                           , '\/'
                           -- registration_tree
                           , '([^a-z.]+\.)?'
                           -- subtype
                           , '([-a-zA-Z0-9.]+)'
                           -- suffix
                           , '(?:\+([-a-zA-Z0-9.]+))?'
                           -- parameter(s) delimited by semicolon and values optionally quoted
                           , '((?:;\s?[a-z]+=(?:"[a-zA-Z0-9\.\-\+\s]{1,70}"|[a-zA-Z0-9\.\-\+]{1,70}))*)$'
                         )
                       ) parts
  )
  SELECT p_media_type
       , matched.parts[1]
       , matched.parts[2]
       , matched.parts[3]
       , matched.parts[4]
       , regexp_replace( matched.parts[5], '^;\s?', '' )
       , jsonb_media_type_parameters( matched.parts[5] )
       , CASE WHEN matched.parts[2] = 'vnd.' THEN 'v'
              WHEN matched.parts[2] = 'prs.' THEN 'p'
              WHEN matched.parts[2] = 'x.' OR matched.parts[3] ~* '^X-' THEN 'u'
              ELSE 's'
         END
    FROM matched
   WHERE matched.parts IS NOT NULL
       ;
$$; COMMENT ON FUNCTION media_type(text) IS
'Checks if the provided string matches a valid media type by whether it
follows the established rules according to RFC specifications.
This function does not check against all the media types listed by the IANA
(https://www.iana.org/assignments/media-types/media-types.xhtml) due to memory
efficiency; it would require including all known media types (2297) but for no
appreciable benefit given the use of "almost right" media types in common use
as well as a significant number of custom types used per-organization.

NOTE: IANA started calling them media types instead of MIME types, but they are the
same thing.

Returns a record if it is a valid media type (NULLs otherwise)
  - mime_type: original validated string passed in
  - type: main type, e.g., text, images, video
  - registration_tree: a categorization string
  - subtype: e.g., png or jpeg for an image type
  - suffix: e.g., xml for image/svg+xml
  - parameters: raw parameter string
  - jsonb_parameters: parsed key-value pairs
  - category:
    v: vendor-specific, e.g.,

More informations in the RFC specifications:
- https://tools.ietf.org/html/rfc2045
- https://tools.ietf.org/html/rfc2046
- https://tools.ietf.org/html/rfc6657
- https://tools.ietf.org/html/rfc7231#section-3.1.1.1
- https://tools.ietf.org/html/rfc7231#section-3.1.1.5
';

CREATE DOMAIN media_type
           AS text
        CHECK ( length_in(VALUE, 1, 126)
                AND NOT media_type(VALUE) IS NULL
              )
            ;
COMMENT ON DOMAIN media_type IS
'Accepts valid media types (formerly known as MIME types).

Length limited to 126 characters simply for internal PostgreSQL storage
efficiency.';

--       _                       _
--      | |                     (_)
--    __| | ___  _ __ ___   __ _ _ _ __
--   / _` |/ _ \| '_ ` _ \ / _` | | '_ \
--  | (_| | (_) | | | | | | (_| | | | | |
--   \__,_|\___/|_| |_| |_|\__,_|_|_| |_|
--   _ __   __ _ _ __ ___   ___
--  | '_ \ / _` | '_ ` _ \ / _ \
--  | | | | (_| | | | | | |  __/
--  |_| |_|\__,_|_| |_| |_|\___|

CREATE FUNCTION domain_name_expanded( IN  p_domain      text
                                    , OUT domain_name   varchar(255)
                                    , OUT hostname      varchar(63)
                                    , OUT parent_domain varchar(253)
                                    , OUT tld           varchar(63)
                                    )
        RETURNS record LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
  WITH fqdn AS (
    SELECT regexp_match( p_domain
                       , '^([a-z0-9](?:[-a-z0-9]{0,61}[a-z0-9])?)((?:\.[a-z0-9](?:[-a-z0-9]{0,61}[a-z0-9])?)*)\.?$'
                       )
           AS parts
  )
  SELECT p_domain                                           AS domain_name
       , fqdn.parts[1]                                      AS hostname
       , substring( fqdn.parts[2] FROM 2 )                  AS parent
       , ( regexp_match( fqdn.parts[2], '\.([^.]+)$' ) )[1] AS tld
    FROM fqdn
   WHERE fqdn.parts IS NOT NULL
       ;
$$; COMMENT ON FUNCTION domain_name_expanded(text) IS
'RFC-1123-compliant domain validation and introspection.';

CREATE DOMAIN domain_name
           AS text
        CHECK ( length_in(VALUE, 1, 255)
                AND NOT domain_name_expanded(VALUE) IS NULL
              )
            ;
COMMENT ON DOMAIN domain_name IS
'Accepts valid domain names.

"URI producers should use names that conform to the DNS syntax, even when use
of DNS is not immediately apparent, and should limit these names to no more
than 255 characters in length."
http://tools.ietf.org/html/rfc3986

"The DNS itself places only one restriction on the particular labels that can
be used to identify resource records. That one restriction relates to the
length of the label and the full name. The length of any one label is limited
to between 1 and 63 octets. A full domain name is limited to 255 octets
(including the separators)."
http://tools.ietf.org/html/rfc2181';

--    __       _ _                               _ _  __ _          _
--   / _|     | | |                             | (_)/ _(_)        | |
--  | |_ _   _| | |_   _ ______ __ _ _   _  __ _| |_| |_ _  ___  __| |
--  |  _| | | | | | | | |______/ _` | | | |/ _` | | |  _| |/ _ \/ _` |
--  | | | |_| | | | |_| |     | (_| | |_| | (_| | | | | | |  __/ (_| |
--  |_|  \__,_|_|_|\__, |      \__, |\__,_|\__,_|_|_|_| |_|\___|\__,_|
--       _          __/ |        _| |
--      | |        |___/        (_)_|
--    __| | ___  _ __ ___   __ _ _ _ __    _ __   __ _ _ __ ___   ___
--   / _` |/ _ \| '_ ` _ \ / _` | | '_ \  | '_ \ / _` | '_ ` _ \ / _ \
--  | (_| | (_) | | | | | | (_| | | | | | | | | | (_| | | | | | |  __/
--   \__,_|\___/|_| |_| |_|\__,_|_|_| |_| |_| |_|\__,_|_| |_| |_|\___|

CREATE DOMAIN fqdn
           AS text
        CHECK (length_in(VALUE, 1, 255) AND (domain_name_expanded(VALUE)).parent_domain IS NOT NULL)
            ;
COMMENT ON DOMAIN fqdn IS
'Accepts valid fully-qualified domain names (FQDN), which are domain names that
include both a hostname and a parent domain.

"URI producers should use names that conform to the DNS syntax, even when use
of DNS is not immediately apparent, and should limit these names to no more
than 255 characters in length."
http://tools.ietf.org/html/rfc3986

"The DNS itself places only one restriction on the particular labels that can
be used to identify resource records. That one restriction relates to the
length of the label and the full name. The length of any one label is limited
to between 1 and 63 octets. A full domain name is limited to 255 octets
(including the separators)."
http://tools.ietf.org/html/rfc2181';

--   _                ___                          _
--  | |              / (_)                        | |
--  | |_ ___ _ __   / / _ _ __    _ __   ___  _ __| |_
--  | __/ __| '_ \ / / | | '_ \  | '_ \ / _ \| '__| __|
--  | || (__| |_) / /  | | |_) | | |_) | (_) | |  | |_
--   \__\___| .__/_/   |_| .__/  | .__/ \___/|_|   \__|
--          | |          | |     | |
--          |_|          |_|     |_|

CREATE FUNCTION is_tcpip_port(p_port int4)
        RETURNS bool LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
  SELECT p_port BETWEEN 1 AND 65535;
$$; COMMENT ON FUNCTION is_tcpip_port(int4) IS
'TCP/IP port as specified in RFC-1700.';

CREATE DOMAIN tcpip_port
           AS int4
        CHECK (is_tcpip_port(VALUE))
            ;
COMMENT ON DOMAIN tcpip_port IS
'TCP/IP ports range from 1 to 65535 (unsigned 16-bit integer, excluding zero).';

--                        _ _
--                       (_) |
--    ___ _ __ ___   __ _ _| |
--   / _ \ '_ ` _ \ / _` | | |
--  |  __/ | | | | | (_| | | |
--   \___|_| |_| |_|\__,_|_|_|

CREATE FUNCTION email_expanded( p_email varchar(254)
                              , OUT email varchar(254)
                              , OUT username text
                              , OUT domain text
                              )
        RETURNS record LANGUAGE sql STRICT IMMUTABLE PARALLEL RESTRICTED AS $$
  WITH address AS (
    SELECT regexp_match(
             p_email
           , '^(([a-z0-9!#$%&''*+/=?^_\`{|}~.-]+)@([a-z0-9-]+(?:\.[a-z0-9-]+)*))$'
           , 'i'
           ) parts
  )
  SELECT a.parts[1] email
       , a.parts[2] username
       , a.parts[3] domain
    FROM address a
   WHERE a.parts IS NOT NULL
       ;
$$; COMMENT ON FUNCTION email_expanded(text) IS
'HTML5 spec compliant email pattern (same as <input type="email"> for most browsers)
Must be at least 3 characters, eg., ''a@b''

Length limited to 254 characters (https://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690)';

CREATE DOMAIN email
           AS text
        CHECK ( VALUE IS NULL
                OR ( length_in(VALUE, 1, 254)
                     AND NOT email_expanded(VALUE) IS NULL
                   )
              )
            ;
COMMENT ON DOMAIN email IS
'Accepts valid email addresses.

Length limited to 254 characters (https://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690)';

CREATE FUNCTION name_from_email(p_email email)
        RETURNS text LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
    SELECT initcap(regexp_replace((email_expanded(p_email)).username, '[^a-zA-Z]', ' '))
         ;
$$;

--              _
--             (_)
--   _   _ _ __ _
--  | | | | '__| |
--  | |_| | |  | |
--   \__,_|_|  |_|

CREATE FUNCTION uri_decode(p_uri_part text, p_encoding text = 'UTF8')
        RETURNS text LANGUAGE sql STRICT IMMUTABLE PARALLEL RESTRICTED AS $$
  (
     SELECT p_uri_part
      WHERE p_uri_part !~ '%|\+'
  UNION ALL
     SELECT replace(p_uri_part, '+', ' ')
      WHERE p_uri_part !~ '%'
  UNION ALL
     SELECT convert_from(
              string_agg(
                CASE WHEN rm[1] IS NULL THEN decode(rm[2], 'hex')
                     WHEN rm[2] IS NULL THEN convert_to(rm[1], 'UTF8')
                     ELSE convert_to(rm[1], 'LATIN1') || decode(rm[2], 'hex')
                END
              , ''::bytea
              )
            , p_encoding
            )
      FROM regexp_matches(replace(p_uri_part, '+', ' '), '([^%]+)?(?:%([a-f0-9]{2}))?', 'ig') AS rm
  ) LIMIT 1;
$$; COMMENT ON FUNCTION uri_decode(text, text) IS
'Convert percent encoding back to its original text. An optional encoding type
can be provided though UTF-8 is the default (and generally preferred).';

CREATE FUNCTION query_string_to_jsonb(p_query text)
        RETURNS jsonb LANGUAGE sql STRICT IMMUTABLE PARALLEL RESTRICTED AS $$
  WITH all_params AS (
    SELECT uri_decode(param.pair[1])            key
         , array_agg(uri_decode(param.pair[2])) value
      FROM regexp_split_to_table(regexp_replace(p_query, '^\?', ''), '&') query(parameter)
     CROSS JOIN LATERAL regexp_split_to_array(query.parameter, '=')       param(pair)
     GROUP BY param.pair[1]
  )
  SELECT jsonb_object_agg(
           key
         , CASE WHEN array_length(value, 1) < 2 THEN to_json(value[1])
                ELSE to_json(value) END
         )
    FROM all_params;
$$; COMMENT ON FUNCTION query_string_to_jsonb(text) IS
'Parse a raw query string into a object of key-value pairs. When a key occurs
more than once, the values are put in an array.';

CREATE FUNCTION uri_expanded( IN  p_uri            varchar(2047)
                            , OUT href             varchar(2047)
                            , OUT protocol         varchar(15)
                            , OUT username         varchar(126)
                            , OUT password         text
                            , OUT hostname         varchar(256)
                            , OUT port             int4
                            , OUT host             varchar(256)
                            , OUT pathname         text
                            , OUT absolute_path    bool
                            , OUT search           text
                            , OUT hash             text
                            , OUT origin           varchar(278)
                            , OUT query_parameters jsonb
                            )
        RETURNS RECORD LANGUAGE sql STRICT IMMUTABLE PARALLEL RESTRICTED AS $$
  WITH matcher AS (
    SELECT regexp_match(
             p_uri
           , concat(
               '(?:' -- optional origin
             ,   '^(?:([a-z][-.+a-z0-9]{0,14}):(?://)?|//)' -- protocol+separator
             ,   '(?:' -- non-capturing user/password pair
             ,     '((?:[a-z][-a-z0-9._+]*|%[0-9a-z]{2})+)' -- user
             ,     '(?::((?:[-/a-z0-9._~!$&''()*+,;=:]+|%[0-9a-z]{2})*))?' -- password
             ,   '@)?' -- user and password are optional
             ,   '([a-z0-9](?:[-a-z0-9]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[-a-z0-9]{0,61}[a-z0-9])?)*)?' -- host
             ,   '(?::(\d{1,5}))?' -- port
             , ')?' -- end optional origin
             , '((?:[-/a-z0-9._~!$&''()*+,;=:@]+|%[0-9a-z]{2})+)?' -- path
             , '(\?(?:[-/a-z0-9._~!$&''()*+,;=:@]+|%[0-9a-z]{2})+)?' -- query string
             , '(#(?:[-/a-z0-9._~!$&''()*+,;=:@]+|%[0-9a-z]{2})+)?' -- hash
             )
           , 'i' -- case insensitive
           )
           uri_parts
  )
  (  SELECT p_uri                                      href
          , split_part(p_uri, ':', 1)::text            protocol
          , NULL::text                                 username
          , NULL::text                                 password
          , NULL::text                                 hostname
          , NULL::int4                                 port
          , NULL::text                                 host
          , regexp_replace(p_uri, '^[^:]+:', '')::text pathname
          , NULL::bool                                 absolute_path
          , NULL::text                                 search
          , NULL::text                                 hash
          , NULL::text                                 origin
          , NULL::jsonb                                query_parameters
      WHERE p_uri ~* '^(?:jdbc|data):'
  UNION ALL
     SELECT p_uri                                 href
          , m.uri_parts[1]                        protocol
          , m.uri_parts[2]                        username
          , m.uri_parts[3]                        password
          , m.uri_parts[4]                        hostname
          , m.uri_parts[5]::int4                  port
          , CASE WHEN m.uri_parts[5] IS NULL THEN m.uri_parts[4]
                 ELSE concat(m.uri_parts[4], ':', m.uri_parts[5])
            END                                   host
          , m.uri_parts[6]                        pathname
          , m.uri_parts[6] ~ '^/'                 absolute_path
          , m.uri_parts[7]                        search
          , m.uri_parts[8]                        hash
          , CASE WHEN m.uri_parts[1] IS NOT NULL AND m.uri_parts[4] IS NOT NULL
                      THEN concat( m.uri_parts[1]
                                 , '://'
                                 , m.uri_parts[4]
                                 , CASE WHEN m.uri_parts[5] IS NOT NULL               THEN ':' || m.uri_parts[5]
                                        WHEN m.uri_parts[1] IN ('https', 'wss')       THEN ':443'
                                        WHEN m.uri_parts[1] IN ('http', 'ws')         THEN ':80'
                                        WHEN m.uri_parts[1] = 'ftp'                   THEN ':21'
                                        WHEN m.uri_parts[1] = 'news'                  THEN ':119'
                                        WHEN m.uri_parts[1] = 'telnet'                THEN ':23'
                                        WHEN m.uri_parts[1] IN ('ssh', 'sftp', 'scp') THEN ':22'
                                        ELSE ''
                                   END
                                 )
            END                                   origin
          , query_string_to_jsonb(m.uri_parts[7]) query_parameters
       FROM matcher m
      WHERE m.uri_parts IS NOT NULL
            AND array_remove(m.uri_parts, NULL) <> '{}'::text[]
  ) LIMIT 1
  ;
$$; COMMENT ON FUNCTION uri_expanded(varchar) IS
'Expand a URI string into its constituent parts using the Location web
interface as a model.
https://developer.mozilla.org/en-US/docs/Web/API/Location';

CREATE DOMAIN uri
           AS text
        CHECK ( length_in(VALUE, 1, 2047)
                AND ( VALUE IS NULL
                      OR NOT uri_expanded(VALUE) IS NULL
                    )
              )
            ;
COMMENT ON DOMAIN uri IS
'Accepts valid URLs.

Length limited to 2047 characters (https://stackoverflow.com/questions/417142/what-is-the-maximum-length-of-a-url-in-different-browsers)';

RESET search_path;

COMMIT;
