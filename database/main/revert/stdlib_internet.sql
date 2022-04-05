-- Revert geekspeak:stdlib_internet from pg

BEGIN
;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib
;

DROP FUNCTION name_from_email(email)
;

DROP DOMAIN media_type
          , domain_name
          , fqdn
          , tcpip_port
          , email
          , uri
;

DROP FUNCTION jsonb_media_type_parameters(text)
            , media_type(text)
            , domain_name_expanded(text)
            , is_tcpip_port(int4)
            , email_expanded(varchar)
            , uri_decode(text, text)
            , query_string_to_jsonb(text)
            , uri_expanded(varchar)
;

RESET search_path
;

COMMIT
;
