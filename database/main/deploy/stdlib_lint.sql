-- Deploy geekspeak:stdlib_lint to pg
-- requires: stdlib

BEGIN;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public;

CREATE TABLE reserved_word (
    word text PRIMARY KEY
         CHECK (length_in(word, 1, 126))
, reason text
);

CREATE FUNCTION is_reserved(p_word text)
        RETURNS bool LANGUAGE sql STRICT STABLE PARALLEL SAFE AS $$
  SELECT count(rw.word) > 0
    FROM reserved_word rw
   WHERE word = lower(p_word)
       ;
$$;

INSERT INTO reserved_word (word)
     VALUES ( 'abs' )
          , ( 'acos' )
          , ( 'all' )
          , ( 'allocate' )
          , ( 'alter' )
          , ( 'analyse' )
          , ( 'analyze' )
          , ( 'and' )
          , ( 'any' )
          , ( 'are' )
          , ( 'array' )
          , ( 'array_agg' )
          , ( 'array_max_cardinality' )
          , ( 'as' )
          , ( 'asc' )
          , ( 'asensitive' )
          , ( 'asin' )
          , ( 'asymmetric' )
          , ( 'at' )
          , ( 'atan' )
          , ( 'atomic' )
          , ( 'authorization' )
          , ( 'avg' )
          , ( 'begin' )
          , ( 'begin_frame' )
          , ( 'begin_partition' )
          , ( 'between' )
          , ( 'bigint' )
          , ( 'binary' )
          , ( 'blob' )
          , ( 'bool' )
          , ( 'both' )
          , ( 'by' )
          , ( 'call' )
          , ( 'called' )
          , ( 'cardinality' )
          , ( 'cascaded' )
          , ( 'case' )
          , ( 'cast' )
          , ( 'ceil' )
          , ( 'ceiling' )
          , ( 'char' )
          , ( 'character' )
          , ( 'character_length' )
          , ( 'char_length' )
          , ( 'check' )
          , ( 'classifier' )
          , ( 'clob' )
          , ( 'close' )
          , ( 'coalesce' )
          , ( 'collate' )
          , ( 'collation' )
          , ( 'collect' )
          , ( 'column' )
          , ( 'commit' )
          , ( 'concurrently' )
          , ( 'condition' )
          , ( 'connect' )
          , ( 'constraint' )
          , ( 'contains' )
          , ( 'convert' )
          , ( 'copy' )
          , ( 'corr' )
          , ( 'corresponding' )
          , ( 'cos' )
          , ( 'cosh' )
          , ( 'decfloat' )
          , ( 'count' )
          , ( 'covar_pop' )
          , ( 'covar_samp' )
          , ( 'create' )
          , ( 'cross' )
          , ( 'cube' )
          , ( 'cume_dist' )
          , ( 'current' )
          , ( 'current_catalog' )
          , ( 'current_date' )
          , ( 'current_default_transform_group' )
          , ( 'current_path' )
          , ( 'current_role' )
          , ( 'current_row' )
          , ( 'current_schema' )
          , ( 'current_time' )
          , ( 'current_timestamp' )
          , ( 'current_transform_group_for_type' )
          , ( 'current_user' )
          , ( 'cursor' )
          , ( 'cycle' )
          , ( 'datalink' )
          , ( 'date' )
          , ( 'day' )
          , ( 'deallocate' )
          , ( 'dec' )
          , ( 'decimal' )
          , ( 'declare' )
          , ( 'default' )
          , ( 'deferrable' )
          , ( 'define' )
          , ( 'delete' )
          , ( 'dense_rank' )
          , ( 'deref' )
          , ( 'desc' )
          , ( 'describe' )
          , ( 'deterministic' )
          , ( 'disconnect' )
          , ( 'distinct' )
          , ( 'dlnewcopy' )
          , ( 'dlpreviouscopy' )
          , ( 'dlurlcomplete' )
          , ( 'dlurlcompleteonly' )
          , ( 'dlurlcompletewrite' )
          , ( 'dlurlpath' )
          , ( 'dlurlpathonly' )
          , ( 'dlurlpathwrite' )
          , ( 'dlurlscheme' )
          , ( 'dlurlserver' )
          , ( 'dlvalue' )
          , ( 'do' )
          , ( 'double' )
          , ( 'drop' )
          , ( 'dynamic' )
          , ( 'each' )
          , ( 'element' )
          , ( 'else' )
          , ( 'empty' )
          , ( 'end' )
          , ( 'end-exec' )
          , ( 'end_frame' )
          , ( 'end_partition' )
          , ( 'equals' )
          , ( 'escape' )
          , ( 'every' )
          , ( 'except' )
          , ( 'exception' )
          , ( 'exec' )
          , ( 'execute' )
          , ( 'exists' )
          , ( 'exp' )
          , ( 'external' )
          , ( 'extract' )
          , ( 'false' )
          , ( 'fetch' )
          , ( 'filter' )
          , ( 'first_value' )
          , ( 'float' )
          , ( 'floor' )
          , ( 'for' )
          , ( 'foreign' )
          , ( 'frame_row' )
          , ( 'free' )
          , ( 'freeze' )
          , ( 'from' )
          , ( 'full' )
          , ( 'function' )
          , ( 'fusion' )
          , ( 'get' )
          , ( 'global' )
          , ( 'grant' )
          , ( 'group' )
          , ( 'grouping' )
          , ( 'groups' )
          , ( 'having' )
          , ( 'hold' )
          , ( 'hour' )
          , ( 'identity' )
          , ( 'ilike' )
          , ( 'import' )
          , ( 'in' )
          , ( 'indicator' )
          , ( 'initial' )
          , ( 'initially' )
          , ( 'inner' )
          , ( 'inout' )
          , ( 'insensitive' )
          , ( 'insert' )
          , ( 'int' )
          , ( 'integer' )
          , ( 'intersect' )
          , ( 'intersection' )
          , ( 'interval' )
          , ( 'into' )
          , ( 'is' )
          , ( 'isnull' )
          , ( 'join' )
          , ( 'json_array' )
          , ( 'json_arrayagg' )
          , ( 'json_exists' )
          , ( 'json_object' )
          , ( 'json_objectagg' )
          , ( 'json_query' )
          , ( 'json_table' )
          , ( 'json_table_primitive' )
          , ( 'json_value' )
          , ( 'lag' )
          , ( 'language' )
          , ( 'large' )
          , ( 'last_value' )
          , ( 'lateral' )
          , ( 'lead' )
          , ( 'leading' )
          , ( 'left' )
          , ( 'like' )
          , ( 'like_regex' )
          , ( 'limit' )
          , ( 'listagg' )
          , ( 'ln' )
          , ( 'local' )
          , ( 'localtime' )
          , ( 'localtimestamp' )
          , ( 'log' )
          , ( 'log10' )
          , ( 'lower' )
          , ( 'match' )
          , ( 'matches' )
          , ( 'match_number' )
          , ( 'match_recognize' )
          , ( 'max' )
          , ( 'max_cardinality' )
          , ( 'measures' )
          , ( 'member' )
          , ( 'merge' )
          , ( 'method' )
          , ( 'min' )
          , ( 'minute' )
          , ( 'mod' )
          , ( 'modifies' )
          , ( 'module' )
          , ( 'month' )
          , ( 'multiset' )
          , ( 'national' )
          , ( 'natural' )
          , ( 'nchar' )
          , ( 'nclob' )
          , ( 'new' )
          , ( 'no' )
          , ( 'none' )
          , ( 'normalize' )
          , ( 'not' )
          , ( 'notnull' )
          , ( 'nth_value' )
          , ( 'ntile' )
          , ( 'null' )
          , ( 'nullif' )
          , ( 'numeric' )
          , ( 'occurrences_regex' )
          , ( 'octet_length' )
          , ( 'of' )
          , ( 'offset' )
          , ( 'old' )
          , ( 'omit' )
          , ( 'on' )
          , ( 'one' )
          , ( 'only' )
          , ( 'open' )
          , ( 'or' )
          , ( 'order' )
          , ( 'out' )
          , ( 'outer' )
          , ( 'over' )
          , ( 'overlaps' )
          , ( 'overlay' )
          , ( 'parameter' )
          , ( 'partition' )
          , ( 'pattern' )
          , ( 'per' )
          , ( 'percent' )
          , ( 'percentile_cont' )
          , ( 'percentile_disc' )
          , ( 'percent_rank' )
          , ( 'period' )
          , ( 'permute' )
          , ( 'placing' )
          , ( 'portion' )
          , ( 'position' )
          , ( 'position_regex' )
          , ( 'power' )
          , ( 'precedes' )
          , ( 'precision' )
          , ( 'prepare' )
          , ( 'primary' )
          , ( 'procedure' )
          , ( 'ptf' )
          , ( 'range' )
          , ( 'rank' )
          , ( 'reads' )
          , ( 'real' )
          , ( 'recursive' )
          , ( 'ref' )
          , ( 'references' )
          , ( 'referencing' )
          , ( 'regr_avgx' )
          , ( 'regr_avgy' )
          , ( 'regr_count' )
          , ( 'regr_intercept' )
          , ( 'regr_r2' )
          , ( 'regr_slope' )
          , ( 'regr_sxx' )
          , ( 'regr_sxy' )
          , ( 'regr_syy' )
          , ( 'release' )
          , ( 'result' )
          , ( 'return' )
          , ( 'returning' )
          , ( 'returns' )
          , ( 'revoke' )
          , ( 'right' )
          , ( 'rollback' )
          , ( 'rollup' )
          , ( 'row' )
          , ( 'rows' )
          , ( 'row_number' )
          , ( 'running' )
          , ( 'savepoint' )
          , ( 'scope' )
          , ( 'scroll' )
          , ( 'search' )
          , ( 'second' )
          , ( 'seek' )
          , ( 'select' )
          , ( 'sensitive' )
          , ( 'session_user' )
          , ( 'set' )
          , ( 'setof' )
          , ( 'show' )
          , ( 'similar' )
          , ( 'sin' )
          , ( 'sinh' )
          , ( 'skip' )
          , ( 'smallint' )
          , ( 'some' )
          , ( 'specific' )
          , ( 'specifictype' )
          , ( 'sql' )
          , ( 'sqlexception' )
          , ( 'sqlstate' )
          , ( 'sqlwarning' )
          , ( 'sqrt' )
          , ( 'start' )
          , ( 'static' )
          , ( 'stddev_pop' )
          , ( 'stddev_samp' )
          , ( 'submultiset' )
          , ( 'subset' )
          , ( 'substring' )
          , ( 'substring_regex' )
          , ( 'succeeds' )
          , ( 'sum' )
          , ( 'symmetric' )
          , ( 'system' )
          , ( 'system_time' )
          , ( 'system_user' )
          , ( 'table' )
          , ( 'tablesample' )
          , ( 'tan' )
          , ( 'tanh' )
          , ( 'then' )
          , ( 'time' )
          , ( 'timestamp' )
          , ( 'timezone_hour' )
          , ( 'timezone_minute' )
          , ( 'to' )
          , ( 'trailing' )
          , ( 'translate' )
          , ( 'translate_regex' )
          , ( 'translation' )
          , ( 'treat' )
          , ( 'trigger' )
          , ( 'trim' )
          , ( 'trim_array' )
          , ( 'true' )
          , ( 'truncate' )
          , ( 'usecape' )
          , ( 'union' )
          , ( 'unique' )
          , ( 'unknown' )
          , ( 'unmatched' )
          , ( 'unnest' )
          , ( 'update' )
          , ( 'upper' )
          , ( 'user' )
          , ( 'using' )
          , ( 'value' )
          , ( 'values' )
          , ( 'value_of' )
          , ( 'varbinary' )
          , ( 'text' )
          , ( 'variadic' )
          , ( 'varying' )
          , ( 'var_pop' )
          , ( 'var_samp' )
          , ( 'verbose' )
          , ( 'versioning' )
          , ( 'when' )
          , ( 'whenever' )
          , ( 'where' )
          , ( 'width_bucket' )
          , ( 'window' )
          , ( 'with' )
          , ( 'within' )
          , ( 'without' )
          , ( 'xml' )
          , ( 'xmlagg' )
          , ( 'xmlattributes' )
          , ( 'xmlbinary' )
          , ( 'xmlcast' )
          , ( 'xmlcomment' )
          , ( 'xmlconcat' )
          , ( 'xmldocument' )
          , ( 'xmlelement' )
          , ( 'xmlexists' )
          , ( 'xmlforest' )
          , ( 'xmliterate' )
          , ( 'xmlnamespaces' )
          , ( 'xmlparse' )
          , ( 'xmlpi' )
          , ( 'xmlquery' )
          , ( 'xmlserialize' )
          , ( 'xmltable' )
          , ( 'xmltext' )
          , ( 'xmlvalidate' )
          , ( 'year' )
ON CONFLICT (word) DO NOTHING
          ;

CREATE FUNCTION raise( p_level   varchar(10)
                     , p_errcode varchar(5)
                     , p_message text
                     , p_detail  text
                     , p_hint    text
                     )
        RETURNS void LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL UNSAFE AS $$
  BEGIN
    -- Leave a blank line after each message.
    -- Note: You'd think '\n' would work. Nope.
    p_hint = p_hint || '
';

    IF p_level = 'DISABLED' THEN
      -- Do nothing
    ELSEIF p_level = 'WARNING' THEN
      RAISE WARNING   USING MESSAGE = p_message, DETAIL = p_detail, HINT = p_hint, ERRCODE = p_errcode;
    ELSEIF p_level = 'NOTICE'  THEN
      RAISE NOTICE    USING MESSAGE = p_message, DETAIL = p_detail, HINT = p_hint, ERRCODE = p_errcode;
    ELSEIF p_level = 'INFO'    THEN
      RAISE INFO      USING MESSAGE = p_message, DETAIL = p_detail, HINT = p_hint, ERRCODE = p_errcode;
    ELSEIF p_level = 'LOG'     THEN
      RAISE LOG       USING MESSAGE = p_message, DETAIL = p_detail, HINT = p_hint, ERRCODE = p_errcode;
    ELSEIF p_level = 'DEBUG'   THEN
      RAISE DEBUG     USING MESSAGE = p_message, DETAIL = p_detail, HINT = p_hint, ERRCODE = p_errcode;
    ELSE -- EXCEPTION
      RAISE EXCEPTION USING MESSAGE = p_message, DETAIL = p_detail, HINT = p_hint, ERRCODE = p_errcode;
    END IF;
  END;
$$;

CREATE FUNCTION lint_level( p_tag           text
                          , p_default_level text
                          , p_comment       text
                          )
        RETURNS text LANGUAGE sql STABLE PARALLEL UNSAFE AS $$
  SELECT CASE WHEN conf.option_value = 'EXCEPTION'
                   THEN 'EXCEPTION'
              WHEN p_comment IS NOT NULL
                   AND p_comment ~ concat('(^|\n)@ignore-lint\s+', upper(p_tag), '\s+.+(\n|$)')
                   THEN 'DISABLED'
              ELSE upper(coalesce(conf.option_value, p_default_level))
         END
    FROM ( VALUES ( 'LINT_' || upper(p_tag) ) ) input(option_name)
    LEFT JOIN config AS conf USING (option_name)
  ;
$$;

CREATE FUNCTION lint_relation( p_default_level text
                             , p_values        jsonb
                             )
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE PARALLEL UNSAFE AS $$
  DECLARE
    level text;
  BEGIN
    level = lint_level('RELATION_CASE_SENSITIVE', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND NOT p_values->>'name' ~ '^[_a-z][_a-z0-9]*$'
       AND p_values->>'name' NOT IN ('SequelizeMeta')
       THEN PERFORM raise( level
                         , '01000'
                         , 'RELATION_CASE_SENSITIVE : Relation name is case sensitive'
                         , format( '%1$I.%2$I has been made case-sensitive.'
                                 , p_values->>'schema'
                                 , p_values->>'name'
                                 )
                         , 'Do not use quotes when defining relations to avoid reserved word and case sensitivity issues. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-upper-case-table-column-and-other-object-names'
                         );
    END IF;

    level = lint_level('RELATION_PLURAL', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       -- Look for trailing 's' but ignore singular words like "kiss", "boss", or "address"
       AND p_values->>'name' ~ '[^s]s$'
       THEN PERFORM raise( level
                         , '01000'
                         , 'RELATION_PLURAL : Relation name appears to be plural'
                         , format( '%1$I.%2$I has been made plural instead of singular; Eg. %3$I instead of %2$I'
                                 , p_values->>'schema'
                                 , p_values->>'name'
                                 , regexp_replace(regexp_replace(p_values->>'name', 'ies$', 'y'), 's$', '')
                                 )
                         , E'Use singular names for tables instead of plurals. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#prefer-singular-names-for-relations\n'
                           || E'For configuring Sequelize, see: https://stackoverflow.com/a/23187186/11471381'
                         );
    END IF;

    level = lint_level('RELATION_RESERVED_NAME', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND is_reserved(p_values->>'name')
       THEN PERFORM raise( level
                         , '01000'
                         , 'RELATION_RESERVED_NAME : Relation name uses a reserved word'
                         , format( '%1$I.%2$I uses a reserved word. See: https://www.postgresql.org/docs/current/sql-keywords-appendix.html'
                                 , p_values->>'schema'
                                 , p_values->>'name'
                                 )
                         , 'Avoid reserved words when defining relations. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-reserved-words-for-object-names'
                         );
    END IF;

    level = lint_level('RELATION_PRIMARY_KEY', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND NOT p_values ? 'primaryKey'
       AND NOT p_values ? 'isView'
       AND p_values->>'columnCount' <> '0'
       THEN PERFORM raise( level
                         , '01000'
                         , 'RELATION_PRIMARY_KEY : Table missing a primary key'
                         , format( '%1$I.%2$I does not have a primary key : %3$s.'
                                 , p_values->>'schema'
                                 , p_values->>'name'
                                 , p_values::text
                                 )
                         , 'Tables must have a primary key. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#always-define-a-primary-key-for-a-table'
                         );
    END IF;
  END;
$$;

CREATE FUNCTION lint_column( p_default_level text
                           , p_values jsonb
                           )
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE PARALLEL UNSAFE AS $$
  DECLARE
    level text;
  BEGIN
    level = lint_level('COLUMN_CASE_SENSITIVE', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values->>'name' ~ '[A-Z]'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_CASE_SENSITIVE : Column name is case sensitive'
                         , format( 'Column "%3$I" in %1$I.%2$I has been made case-sensitive.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Do not use quotes when defining columns to avoid reserved word and case sensitivity issues. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-upper-case-table-column-and-other-object-names'
                         );
    END IF;

    level = lint_level('COLUMN_NAME_FORMAT', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values->>'name' ~ '\s'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_NAME_FORMAT : Column name contains non-alphanumeric characters'
                         , format( 'Column "%3$I" in %1$I.%2$I has problematic characters.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Do not use whitespace or punctuation for column names, which can cause security and usage issues. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-column-names-requiring-quotes'
                         );
    END IF;

    level = lint_level('COLUMN_RESERVED_NAME', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND is_reserved(p_values->>'name')
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_RESERVED_NAME : Column name uses a reserved word'
                         , format( 'Column "%3$I" in %1$I.%2$I uses a reserved word.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Avoid reserved words when defining columns. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-reserved-words-for-object-names'
                         );
    END IF;

    level = lint_level('COLUMN_UUID_GENERATED', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values->>'default' ~ 'gen_random_uuid|uuid_generate_v\d'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_UUID_GENERATED : UUID generated within the database'
                         , format( 'Column "%3$I" in %1$I.%2$I generates a UUID within the database instead of in an app or query.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Look into generating the UUID in your app using standard libraries or with SQL explicitly in INSERTs and UPDATEs. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#prefer-generating-uuids-outside-the-database'
                         );
    END IF;

    level = lint_level('COLUMN_PKEY_INTEGER_GENERATED', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values ? 'isPrimaryKey'
       AND p_values->>'type' IN ('smallint', 'integer')
       AND p_values ? 'default'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_PKEY_INTEGER_GENERATED : integer primary key generated within the database'
                         , format( 'Column "%3$I" in %1$I.%2$I generates a %4$s primary key.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 , p_values->>'type'
                                 )
                         , 'Use a random UUID or 64-bit integer for the primary key instead or document why a smaller unit is preferable. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#prefer-uuids-to-integers-for-primary-keys'
                         );
    END IF;

    -- level = lint_level('COLUMN_TEXT_UNBOUNDED', p_default_level, p_values->>'comment');
    -- IF level IS DISTINCT FROM 'DISABLED'
    --     AND p_values->>'type' IN ('character varying', 'text')
    --     AND NOT p_values ? 'typeModifier' THEN
    --   PERFORM raise(level, '01000', 'COLUMN_TEXT_UNBOUNDED : unbounded text column',
    --     format('Column "%3$I" in %1$I.%2$I has no size limit.',
    --       p_values->>'schema', p_values->>'relation', p_values->>'name'),
    --     'Use a bounded text, eg. text CHECK (length_in(eg., 1, 100)), text(5000).');
    -- END IF;

    level = lint_level('COLUMN_TIMESTAMP', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values->>'type' = 'timestamp'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_TIMESTAMP : Timestamp specified without time zone'
                         , format( 'Column "%3$I" in %1$I.%2$I uses a timestamp without a time zone. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#always-use-timestamp-with-time-zone'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Timestamps should always include time zone. Use "timestamptz" or "timestamp with time zone".'
                         );
    END IF;

    level = lint_level('COLUMN_TIME', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values->>'type' = 'timetz'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_TIME : Time specified with a time zone'
                         , format( 'Column "%3$I" in %1$I.%2$I uses a time with a time zone. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-time-with-timezone'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Times should never include time zone. Use "time" instead.'
                         );
    END IF;

    level = lint_level('COLUMN_DEFAULT', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values ? 'default'
       -- nextval(<sequence name>),
       -- CURRENT_USER, CURRENT_TIMESTAMP, now(), SESSION_USER, USER,
       -- clock_timestamp(), current_txid(), etc. are all allowable.
       AND p_values->>'default' !~* '^(?:nextval\([^)]+\)|current_user|current_role|user|session_user|current_timestamp|now\(\d*\)|clock_timestamp\(\)|current_txid\(\))$'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_DEFAULT : Column default specified'
                         , format( 'Column "%3$I" in %1$I.%2$I specifies a default without explanation.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Always document column defaults, especially magic values. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#always-document-column-defaults'
                         );
    END IF;

    level = lint_level('COLUMN_UNENCRYPTED_PASSWORD', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values->>'name' ~* 'password'
       AND NOT p_values->>'type' = 'bytea'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_UNENCRYPTED_PASSWORD : Unencrypted password column'
                         , format( 'Column "%3$I" in %1$I.%2$I contains an unencrypted password.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Use encryption tools for sensitive information like passwords. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#always-encrypt-sensitive-data-and-hash-passwords'
                         );
    END IF;

    level = lint_level('COLUMN_CHAR', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values->>'type' = 'bpchar'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_CHAR : Column uses CHAR type'
                         , format( 'Column "%3$I" in %1$I.%2$I is a CHAR type.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Use text (character varying) instead. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-the-charn-type'
                         );
    END IF;

    level = lint_level('COLUMN_MONEY', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values->>'type' = 'money'
       THEN PERFORM raise( level
                         , '01000'
                         , 'COLUMN_MONEY : Column uses MONEY type'
                         , format( 'Column "%3$I" in %1$I.%2$I is a MONEY type.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Use NUMERIC or INTEGER types instead. (Do not use floating point.) https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#prefer-the-decimal-type-for-currency-money'
                         );
    END IF;

    level = lint_level('COLUMN_INHERITED', p_default_level, p_values->>'comment');
    IF level IS DISTINCT FROM 'DISABLED'
       AND p_values->>'inheritCount' <> '0'
       AND NOT (p_values->>'isLocal')::bool
       THEN PERFORM raise( level
                         , '01000'
                         , 'INHERITED_COLUMN : Column added from another table'
                         , format( 'Column "%3$I" in %1$I.%2$I is added through an inherited table.'
                                 , p_values->>'schema'
                                 , p_values->>'relation'
                                 , p_values->>'name'
                                 )
                         , 'Inheritance should only be used to establish interfaces, not to add columns. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#avoid-inheriting-tables-for-column-creation'
                         );
    END IF;
  END;
$$;

CREATE FUNCTION lint_type( p_default_level text
                         , p_values        jsonb
                         )
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE PARALLEL UNSAFE AS $$
DECLARE
  level text;
BEGIN
  level = lint_level('TYPE_CASE_SENSITIVE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND NOT p_values->>'type_name' ~ '^[_a-z][_a-z0-9]*$' THEN
    PERFORM raise(level, '01000', 'TYPE_CASE_SENSITIVE : Type name is case sensitive',
      format('Type "%1$s" has been made case-sensitive.',
        p_values->>'name'),
      'Do not use quotes when defining types to avoid reserved word and case sensitivity issues. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-upper-case-table-column-and-other-object-names');
  END IF;

  level = lint_level('TYPE_RESERVED_NAME', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND is_reserved(p_values->>'name') THEN
    PERFORM raise(level, '01000', 'TYPE_RESERVED_NAME : Type name uses a reserved word',
      format('Type "%1$s" uses a reserved word.',
        p_values->>'name'),
      'Avoid reserved words when defining types. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-reserved-words-for-object-names');
  END IF;

  level = lint_level('TYPE_CREATE_ENUM', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values ? 'isEnum' THEN
    PERFORM raise(level, '01000', 'TYPE_CREATE_ENUM : Enumerated type created',
      format('Creating enumerated type "%1$s" when more portable and readable alternatives exist.', p_values->>'name'),
      'Use a lookup table and foreign keys instead. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-create-enum-types');
  END IF;

  level = lint_level('TYPE_DOMAIN_NOT_NULL', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values ? 'isDomain'
      AND p_values ? 'isNotNull' THEN
    PERFORM raise(level, '01000', 'TYPE_DOMAIN_NOT_NULL : Domain has NOT NULL constraint',
      format('Domain "%1$s" has NOT NULL constraint.', p_values->>'name'::text),
      'Define the column NOT NULL in the table definition, not in the domain. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-create-a-domain-with-a-not-null-constraint');
  END IF;

  level = lint_level('TYPE_DOMAIN_DEFAULT', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values ? 'isDomain'
      AND p_values ? 'default' THEN
    PERFORM raise(level, '01000', 'TYPE_DOMAIN_DEFAULT : Domain default specified',
      format('Domain "%1$s" specifies a default.', p_values->>'name'::text),
      'Either use the coalesce function or define a default in the table, view, or function.');
  END IF;

  level = lint_level('TYPE_DOMAIN_CHECK', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values ? 'isDomain'
      AND NOT p_values ? 'check' THEN
    PERFORM raise(level, '01000', 'TYPE_DOMAIN_CHECK : Domain missing CHECK constraint',
      format('Domain "%1$s" does not have a CHECK constraint.', p_values->>'name'::text),
      'Add a CHECK constraint to the domain. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#always-create-a-domain-with-a-check-constraint');
  END IF;
END;
$$;

CREATE FUNCTION lint_function( p_default_level text
                             , p_values jsonb
                             )
        RETURNS void LANGUAGE plpgsql STRICT VOLATILE PARALLEL UNSAFE AS $$
DECLARE
  level text;
BEGIN
  level = lint_level('FUNCTION_CASE_SENSITIVE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND NOT p_values->>'name' ~ '^(?:[^.(]+\.)?[_a-z][_a-z0-9]*\(' THEN
    PERFORM raise(level, '01000', 'FUNCTION_CASE_SENSITIVE : Function name is case sensitive',
      format('Function %1$s has been made case-sensitive.',
        p_values->>'name'),
      'Do not use quotes when defining functions to avoid reserved word and case sensitivity issues. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-upper-case-table-column-and-other-object-names');
  END IF;

  level = lint_level('FUNCTION_RESERVED_NAME', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND is_reserved(p_values->>'name') THEN
    PERFORM raise(level, '01000', 'FUNCTION_RESERVED_NAME : Function name uses a reserved word',
      format('Function %1$s uses a reserved word.',
        p_values->>'name'),
      'Avoid reserved words when defining functions. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-reserved-words-for-object-names');
  END IF;

  level = lint_level('FUNCTION_DYNAMIC_SQL', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->>'source' ~* '\bEXECUTE\b' THEN
    PERFORM raise(level, '01000', 'FUNCTION_DYNAMIC_SQL : Dynamic SQL used in a function',
      format('Function %1$s uses dynamic SQL for its processing.', p_values->>'name'),
      'Use a static alternative or document why dynamic SQL is necessary. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#avoid-dynamically-generated-sql');
  END IF;

  level = lint_level('FUNCTION_RETURNS_WITHOUT_TIMEZONE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->>'returns' = 'timestamp' THEN
    PERFORM raise(level, '01000', 'FUNCTION_RETURNS_WITHOUT_TIMEZONE : Function returns a timestamp without a time zone',
      format('Function %1$s returns a timestamp without a time zone.', p_values->>'name'),
      'Timestamps should always include time zone. Return "timestamptz" instead. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#always-use-timestamp-with-time-zone');
  END IF;

  level = lint_level('FUNCTION_CALLED_WITHOUT_TIMEZONE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->'arguments' ? 'timestamp' THEN
    PERFORM raise(level, '01000', 'FUNCTION_CALLED_WITHOUT_TIMEZONE : Function takes a timestamp without a time zone',
      format('Function %1$s takes a timestamp without a time zone.', p_values->>'name'),
      'Timestamps should always include time zone. Use "timestamptz" instead. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#always-use-timestamp-with-time-zone');
  END IF;

  level = lint_level('FUNCTION_RUN_WITHOUT_TIMEZONE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->>'source' ~* '\btimestamp\b' THEN
    PERFORM raise(level, '01000', 'FUNCTION_RUN_WITHOUT_TIMEZONE : Function uses a timestamp without a time zone',
      format('Function %1$s uses a timestamp without a time zone.', p_values->>'name'),
      'Timestamps should always include time zone. Use "timestamptz" instead. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#always-use-timestamp-with-time-zone');
  END IF;

  level = lint_level('FUNCTION_RETURNS_TIMEZONE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->>'returns' = 'timetz' THEN
    PERFORM raise(level, '01000', 'FUNCTION_RETURNS_TIMEZONE : Function returns a time with a time zone',
      format('Function %1$s returns a time with a time zone (timetz).', p_values->>'name'),
      'Times should never include time zone. Return "timestamptz" instead. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-time-with-timezone');
  END IF;

  level = lint_level('FUNCTION_CALLED_WITH_TIMEZONE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->'arguments' ? 'timetz' THEN
    PERFORM raise(level, '01000', 'FUNCTION_CALLED_WITH_TIMEZONE : Function takes a time with a time zone (timetz)',
      format('Function %1$s takes a time with a time zone (timetz).', p_values->>'name'),
      'Times should never include time zone. Use "timestamptz" instead. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-time-with-timezone');
  END IF;

  level = lint_level('FUNCTION_RUN_WITH_TIMEZONE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->>'source' ~* '\btimetz\b' THEN
    PERFORM raise(level, '01000', 'FUNCTION_RUN_WITH_TIMEZONE : Function uses a timestamp without a time zone',
      format('Function %1$s uses a time with a time zone (timetz).', p_values->>'name'),
      'Times should never include time zone. Use "timestamptz" instead. https://github.com/productOps/windmill2-db-lib/wiki/SQL-Style-Guide#never-use-time-with-timezone');
  END IF;

  level = lint_level('FUNCTION_LANGUAGE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND NOT regexp_split_to_array(get_config('LINT_SUPPORTED_LANGUAGES', 'sql,plpgsql'::text), '\s*,\s*') @> ARRAY[p_values->>'language']::text[] THEN
    PERFORM raise(level, '01000', 'FUNCTION_LANGUAGE : Function uses an alternative programming language',
      format('Function %1$s uses an alternative programming language: %2$s', p_values->>'name', p_values->>'language'),
      'Functions should be written in SQL or pl/PgSQL');
  END IF;

  level = lint_level('FUNCTION_NOT_VOLATILE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->>'volatility' = 'v'
      AND p_values->>'source' !~* 'random|\yclock_timestamp\('
      AND p_values->>'returns' NOT IN ('trigger', 'event_trigger') THEN
    PERFORM raise(level, '01000', 'FUNCTION_NOT_VOLATILE : Function incorrectly marked VOLATILE (or not marked)',
      format('Function %1$s is unnecessarily marked VOLATILE, potentially harming performance.', p_values->>'name'),
      'Mark function STABLE or IMMUTABLE unless calling volatile functions like random() or clock_timestamp().');
  END IF;

  level = lint_level('FUNCTION_VOLATILE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->>'volatility' <> 'v'
      AND (
        p_values->>'source' ~* 'random[_a-z0-9A-Z]*\(|\yclock_timestamp\('
        OR p_values->>'returns' IN ('trigger', 'event_trigger')
      ) THEN
    PERFORM raise(level, '01000', 'FUNCTION_VOLATILE : Function should be marked VOLATILE',
      format('Function %1$s is marked %2$s instead of VOLATILE, potentially harming accuracy.',
        p_values->>'name',
        CASE WHEN p_values->>'volatility' = 'i' THEN 'IMMUTABLE' ELSE 'STABLE' END),
      'Mark function VOLATILE.');
  END IF;

  level = lint_level('FUNCTION_STABLE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->>'volatility' <> 's'
      AND p_values->>'source' ~* '\y(?:from\s+[a-z]|insert|update|create|drop|alter|perform)\y'
      AND p_values->>'source' !~* 'random[_a-z0-9A-Z]*\(|\yclock_timestamp\('
      AND p_values->>'returns' NOT IN ('trigger', 'event_trigger') THEN
    PERFORM raise(level, '01000', 'FUNCTION_STABLE : Function should probably be marked STABLE',
      format('Function %1$s is marked %2$s instead of STABLE.',
        p_values->>'name',
        CASE WHEN p_values->>'volatility' = 'i' THEN 'IMMUTABLE' ELSE 'VOLATILE' END),
      'Mark function STABLE.');
  END IF;

  level = lint_level('FUNCTION_IMMUTABLE', p_default_level, p_values->>'comment');
  IF level IS DISTINCT FROM 'DISABLED'
      AND p_values->>'volatility' <> 'i'
      AND p_values->>'source' !~* 'random[_a-z0-9A-Z]*\(|\yclock_timestamp\(|\yfrom\s+[a-z]|\yinsert\y|\yupdate\y|\ycreate\y|\ydrop\y|\yalter\y|\yperform\y'
      AND p_values->>'returns' NOT IN ('trigger', 'event_trigger') THEN
    PERFORM raise(level, '01000', 'FUNCTION_IMMUTABLE : Function should probably be marked IMMUTABLE',
      format('Function %1$s should probably be marked IMMUTABLE to improve performance.', p_values->>'name'),
      'Mark function IMMUTABLE.');
  END IF;
END;
$$;

CREATE FUNCTION lint( p_default_level text = get_config('default_lint_log_level', 'WARNING'))
        RETURNS void LANGUAGE plpgsql STRICT STABLE PARALLEL UNSAFE AS $$
DECLARE
  r     record;
  level text;
BEGIN
  --
  --        TABLE LINT
  --
  PERFORM
    lint_relation(
      p_default_level,
      jsonb_strip_nulls(
        jsonb_build_object(
          'schema', rels.relnamespace::regnamespace::text,
          'name', rels.relname,
          'columnCount', rels.relnatts,
          'isView', NULLIF(rels.relkind IN ('v', 'm'), false),
          'primaryKey', con.conname,
          'comment', d.description
        )
      )
    )
  FROM pg_class AS rels
    -- Part of an extension or is internal
    LEFT JOIN pg_depend AS dep ON (rels.oid = dep.objid AND deptype IN ('e', 'i'))
    -- Relation defaults
    LEFT JOIN pg_constraint AS con ON (rels.oid = con.conrelid AND con.contype = 'p')
    -- Relation comments
    LEFT JOIN pg_description AS d ON (rels.oid = d.objoid AND d.objsubid = 0)
  WHERE rels.relkind IN ('r', 'v', 'm', 'c', 'f')
    AND rels.relpersistence = 'p'
    AND rels.relname !~ '^__'
    AND rels.relnamespace::regnamespace NOT IN ('pg_catalog', 'information_schema')
    AND dep.objid IS NULL -- exclude extension and internal types
  ORDER BY rels.relnamespace, rels.relname;

  --
  --        COLUMN LINT
  --
  PERFORM
    lint_column(
      p_default_level,
      jsonb_strip_nulls(
        jsonb_build_object(
          'schema', rels.relnamespace::regnamespace::text,
          'relation', rels.relname,
          'name', a.attname,
          'type', a.atttypid::regtype::text,
          'isArray', NULLIF(a.attndims > 0, false),
          'notNull', NULLIF(a.attnotnull, false),
          'default', def.adsrc,
          'isLocal', NULLIF(a.attislocal, false),
          'inheritCount', nullif(a.attinhcount, 0),
          'isPrimaryKey', NULLIF(pkey.oid IS NOT NULL, false),
          'typeModifier', NULLIF(a.atttypmod, -1),
          'comment', d.description
        )
      )
    )
  FROM pg_attribute AS a
    INNER JOIN pg_class AS rels ON (a.attrelid = rels.oid)
    -- Part of an extension or is internal
    LEFT JOIN pg_depend AS dep ON (rels.oid = dep.objid AND deptype IN ('e', 'i'))
    -- Column comments
    LEFT JOIN pg_description AS d ON (a.attrelid = d.objoid AND a.attnum = d.objsubid)
    -- Column defaults
    LEFT JOIN pg_attrdef AS def ON (a.atthasdef AND a.attrelid = def.adrelid AND a.attnum = def.adnum)
    LEFT JOIN pg_constraint AS pkey ON (a.attrelid = pkey.conrelid AND pkey.conkey = ARRAY[a.attnum])
  WHERE rels.relnamespace::regnamespace NOT IN ('pg_catalog', 'information_schema')
    AND rels.relname !~ '^__'
    AND rels.relkind IN ('r', 'v', 'm', 'f', 'c')
    AND rels.relpersistence = 'p'
    AND dep.objid IS NULL -- exclude extension and internal types
    AND a.attnum > 0
    AND NOT a.attisdropped
  ORDER BY rels.relnamespace, a.attrelid::regclass::text, a.attnum;

  --
  --        TYPE LINT
  --
  PERFORM lint_type( p_default_level
                   , jsonb_strip_nulls( jsonb_build_object( 'schema', t.typnamespace::regnamespace::text
                                                          , 'name', t.typname
                                                          , 'isDomain', nullif( t.typtype = 'd', false )
                                                          , 'isEnum', nullif( t.typtype = 'e', false )
                                                          , 'default', t.typdefault
                                                          , 'check', c.consrc
                                                          , 'comment', d.description
                                                          )
                                      )
                   )
  FROM pg_type AS t
    -- Type comments
    LEFT JOIN pg_description AS d ON (t.oid = d.objoid)
    -- Domain check constraints
    LEFT JOIN pg_constraint AS c ON (t.oid = c.contypid AND c.contype = 'c')
  WHERE t.typnamespace::regnamespace NOT IN ('pg_catalog', 'information_schema');

  --
  --        FUNCTION LINT
  --
  PERFORM lint_type( p_default_level
                   , jsonb_strip_nulls( jsonb_build_object( 'schema', func.pronamespace::regnamespace::text
                                                          , 'name', func.oid::regprocedure::text
                                                          , 'arguments', func.proargtypes::regtype[]::text[]
                                                          , 'returns', func.prorettype::regtype
                                                          , 'language', lang.lanname
                                                          , 'source', func.prosrc
                                                          , 'isSetuid', nullif( func.prosecdef, false )
                                                          , 'volatility', func.provolatile
                                                          , 'isStrict', nullif( func.proisstrict, false )
                                                          , 'comment', d.description
                                                          )
                                      )
                   )
     FROM pg_proc AS func
          -- Part of an extension or is a system function
     LEFT JOIN pg_depend AS dep ON ((func.oid = dep.objid AND dep.deptype = 'e') OR (func.oid = dep.refobjid AND dep.deptype = 'p'))
          -- Function comments
     LEFT JOIN pg_description AS d ON (func.oid = d.objoid AND d.objsubid = 0)
          -- Programming language
     LEFT JOIN pg_language AS lang ON (func.prolang = lang.oid)
          -- Ignore built-in functions
    WHERE func.pronamespace::regnamespace NOT IN ('pg_catalog', 'information_schema')
          AND lang.lanname NOT IN ('c', 'internal') -- Exclude native functions
          AND dep.objid IS NULL -- Exclude extension functions
    ORDER BY func.oid::regprocedure::text
  ;
END;
$$;
COMMENT ON FUNCTION lint(text) IS
'@ignore-lint FUNCTION_VOLATILE The strings random and clock_timestamp appear, but the functions are not called.';

CREATE FUNCTION lint_column_realtime()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  r record;
BEGIN
  --
  --        COLUMN LINT
  --
  PERFORM lint_column( p_default_level
                     , jsonb_strip_nulls( jsonb_build_object( 'schema', rels.relnamespace::regnamespace::text
                                                            , 'relation', rels.relname
                                                            , 'name', a.attname
                                                            , 'type', a.atttypid::regtype::text
                                                            , 'isArray', a.attndims > 0
                                                            , 'notNull', a.attnotnull
                                                            , 'default', def.adsrc
                                                            , 'isLocal', a.attislocal
                                                            , 'inheritCount', nullif( a.attinhcount, 0 )
                                                            , 'comment', coalesce( d.description, '' )
                                                            )
                                        )
                    )
     FROM pg_event_trigger_ddl_commands() AS et
     JOIN pg_attribute AS a ON (a.attrelid = et.objid AND a.attnum = et.objsubid)
     JOIN pg_class AS rels ON (et.objid = rels.oid)
          -- Column comments
     LEFT JOIN pg_description AS d ON (et.objid = d.objoid AND et.objsubid = d.objsubid)
          -- Column defaults
     LEFT JOIN pg_attrdef AS def ON (a.atthasdef AND a.attrelid = def.adrelid AND a.attnum = def.adnum)
    WHERE rels.relnamespace::regnamespace NOT IN ('pg_catalog', 'information_schema')
          AND a.attnum > 0
          AND NOT a.attisdropped
    ORDER BY rels.relnamespace, a.attrelid::regclass::text, a.attnum
  ;
END;
$$;

CREATE FUNCTION lint_relation_realtime()
        RETURNS EVENT_TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  r record;
BEGIN
  --
  --        TABLE LINT
  --
  PERFORM lint_column( p_default_level
                     , jsonb_strip_nulls( jsonb_build_object( 'schema', rels.relnamespace::regnamespace::text
                                                            , 'name', rels.relname
                                                            , 'comment', coalesce( d.description, '' )
                                                            )
                                        )
                     )
     FROM pg_event_trigger_ddl_commands() et
     JOIN pg_attribute a ON (a.attrelid = et.objid AND a.attnum = et.objsubid)
     JOIN pg_class rels ON (et.objid = rels.oid)
          -- Column comments
     LEFT JOIN pg_description d ON (et.objid = d.objoid AND et.objsubid = d.objsubid)
          -- Column defaults
     LEFT JOIN pg_attrdef def ON (a.atthasdef AND a.attrelid = def.adrelid AND a.attnum = def.adnum)
    WHERE rels.relnamespace::regnamespace NOT IN ('pg_catalog', 'information_schema')
          AND a.attnum > 0
          AND NOT a.attisdropped
    ORDER BY rels.relnamespace, a.attrelid::regclass::text, a.attnum
  ;
END;
$$;

RESET search_path;

COMMIT;
