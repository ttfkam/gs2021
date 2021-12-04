-- Revert geekspeak:stdlib_case_conversion from pg

-- Deploy geekspeak:stdlib_case_conversion to pg

BEGIN;

DROP FUNCTION snake_to_pascal(text)
            , snake_to_camel(text)
            , camel_to_pascal(text)
            , camel_to_snake(text)
            , pascal_to_snake(text)
            , pascal_to_camel(text)
            , snake_to_camel(jsonb)
            , camel_to_snake(jsonb)
            ;

COMMIT;
