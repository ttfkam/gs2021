-- Revert geekspeak:stdlib_lint from pg

BEGIN
;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib
;

DROP FUNCTION is_reserved(text)
            , raise(varchar, varchar, text, text, text)
            , lint_level(text, text, text)
            , lint_relation(text, jsonb)
            , lint_column(text, jsonb)
            , lint_type(text, jsonb)
            , lint_function(text, jsonb)
            , lint(text)
            , lint_column_realtime()
            , lint_relation_realtime()
;

DROP TABLE reserved_word
;

RESET search_path
;

COMMIT
;
