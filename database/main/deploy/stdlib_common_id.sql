-- Deploy geekspeak:stdlib_common_id to pg
-- requires: stdlib

BEGIN
;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public
;

CREATE SEQUENCE lookup_id_seq MAXVALUE 32767
; COMMENT ON SEQUENCE lookup_id_seq IS 'Lookup table ID generator'
;

CREATE SEQUENCE id_seq MINVALUE 32768
; COMMENT ON SEQUENCE id_seq IS 'ID generator'
;

CREATE SEQUENCE test_id_seq
; COMMENT ON SEQUENCE test_id_seq IS 'Test ID generator'
;

CREATE FUNCTION gen_test_uuid()
        RETURNS uuid LANGUAGE sql VOLATILE PARALLEL SAFE AS $$
  SELECT ('0000000000004000' || lpad(to_hex(nextval('test_id_seq')), 16, '0'))::uuid
  ;
$$; COMMENT ON FUNCTION gen_test_uuid() IS
'UUIDs easily identifiable by the prefix of zeros for test data'
;

RESET search_path
;

COMMIT
;
