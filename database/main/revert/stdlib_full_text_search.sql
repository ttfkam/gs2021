-- Revert geekspeak:stdlib_full_text_search from pg

BEGIN
;

-- Make sure everything we drop here is from the stdlib namespace
SET search_path = stdlib
;

DROP FUNCTION
    IF EXISTS search(tsquery)
            , search(text)
            , fts(FTS)
            , fts_trigger()
            , weighted_tsvector(text,"char")
;

DROP TABLE FTS
;

RESET search_path
;

COMMIT
;
