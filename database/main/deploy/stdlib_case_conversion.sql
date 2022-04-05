-- Deploy geekspeak:stdlib_case_conversion to pg

BEGIN
;

CREATE FUNCTION snake_to_pascal(snake_case text)
          RETURNS text LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT replace(initcap(replace(snake_case, '_', ' ')), ' ', '')
    ;
$$; COMMENT ON FUNCTION snake_to_pascal(text) IS
'Convert from snake case to pascal case, eg., snake_to_pascal -> SnakeToPascal';

CREATE FUNCTION snake_to_camel(snake_case text)
                   RETURNS text LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT lower(left(snake_to_pascal(snake_case), 1)) || right(snake_to_pascal(snake_case), -1)
    ;
$$; COMMENT ON FUNCTION snake_to_camel(text) IS
'Convert from snake case to camel case, eg., snake_to_camel -> snakeToCamel';

CREATE FUNCTION camel_to_pascal(camel_case text)
                   RETURNS text LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT upper(left(camel_case, 1)) || right(camel_case, -1)
    ;
$$; COMMENT ON FUNCTION camel_to_pascal(text) IS
'Convert from camel case to pascal case, eg., camel_to_pascal -> CamelToPascal';

CREATE FUNCTION camel_to_snake(camel_case text)
                   RETURNS text LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT lower(regexp_replace(camel_case, '\Y([A-Z])', '_\1', 'g'))
    ;
$$; COMMENT ON FUNCTION camel_to_snake(text) IS
'Convert from camel case to snake case, eg., camelToSnake -> camel_to_snake';

CREATE FUNCTION pascal_to_snake(pascal_case text)
                   RETURNS text LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT camel_to_snake(pascal_case)
    ;
$$; COMMENT ON FUNCTION pascal_to_snake(text) IS
'Convert from pascal case to snake case, eg., PascalToSnake -> pascal_to_snake';

CREATE FUNCTION pascal_to_camel(pascal_case text)
                   RETURNS text LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT lower(left(pascal_case, 1)) || right(pascal_case, -1)
    ;
$$; COMMENT ON FUNCTION pascal_to_camel(text) IS
'Convert from pascal case to camel case, eg., PascalToCamel -> pascalToCamel';

CREATE FUNCTION snake_to_camel(obj jsonb)
                   RETURNS jsonb LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT jsonb_object_agg(snake_to_camel(key), val)
      FROM jsonb_each(obj) kv(key, val)
    ;
$$; COMMENT ON FUNCTION snake_to_camel(jsonb) IS
'Convert from snake case to camel case, eg., { "snake_to_camel": true } -> { "snakeToCamel": true }';

CREATE FUNCTION camel_to_snake(obj jsonb)
                   RETURNS jsonb LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT jsonb_object_agg(camel_to_snake(key), val)
      FROM jsonb_each(obj) kv(key, val)
    ;
$$; COMMENT ON FUNCTION camel_to_snake(jsonb) IS
'Convert from camel case to snake case, eg., { "camelToSnake": true } -> { "camel_to_snake": true }';

COMMIT
;
