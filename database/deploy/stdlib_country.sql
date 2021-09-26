-- Deploy geekspeak:stdlib_country to pg
-- requires: stdlib_config_system_versioning

BEGIN;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public;

CREATE TABLE country (
          alpha_3_code varchar(3) PRIMARY KEY
                       CHECK (alpha_3_code ~ '^[A-Z]{3}$')
,         alpha_2_code varchar(2) NOT NULL UNIQUE
                       CHECK (alpha_2_code ~ '^[A-Z]{2}$')
,         numeric_code varchar(3) NOT NULL UNIQUE
                       CHECK (numeric_code ~ '^\d{3}$')
,                 name text       NOT NULL UNIQUE
                       CHECK (length_in(name, 1, 126))
,        official_name text       NOT NULL UNIQUE
                       CHECK (length_in(official_name, 1, 1000))
,               parent varchar(3)
                       CHECK (parent ~ '^[A-Z]{3}$')
                       REFERENCES country (alpha_3_code)
                               ON UPDATE CASCADE
                               ON DELETE SET NULL
,          sovereignty text
                       CHECK (length_in(sovereignty, 1, 126))
,                 tlds varchar(2)[]
,           recognized tstzrange  NOT NULL
                       DEFAULT '(-infinity, infinity)'
,  postal_code_pattern text
                       CHECK (length_in(postal_code_pattern, 1, 126))
,          tel_pattern text
                       CHECK (length_in(sovereignty, 1, 150))
) INHERITS (SYSTEM_VERSIONED); COMMENT ON TABLE country IS
'An amalgam of ISO-3166, postal code patterns, and telephone number patterns.';
COMMENT ON COLUMN country.alpha_3_code IS
'ISO-3166 3-character country/territory code.';
COMMENT ON COLUMN country.alpha_2_code IS
'ISO-3166 2-character country/territory code. Prefer the 3-character code in
alpha_3_code when possible.';
COMMENT ON COLUMN country.numeric_code IS
'ISO-3166 3-digit numeric country/territory code. Prefer the 3-character code
in alpha_3_code when possible.';
COMMENT ON COLUMN country.name IS
'The simpler, familiar, common name for a country/territory.';
COMMENT ON COLUMN country.official_name IS
'The official (translated to English) name for a country/territory.';
COMMENT ON COLUMN country.parent IS
'If the entry is not a sovereign nation, references the sovereign nation that
governs it.';
COMMENT ON COLUMN country.sovereignty IS
'If the entry is not a sovereign nation but is not controlled by a nation
state, specifies the controlling entity or international treaty.';
COMMENT ON COLUMN country.tlds IS
'The region''s 2-character top level internet (DNS) domains.';
COMMENT ON COLUMN country.recognized IS
'When the nation was first internationally recognized to if/when the entity
ceased to exist in its current form.';
COMMENT ON COLUMN country.postal_code_pattern IS
'Postal code regular expression patterns by country/territory.';
COMMENT ON COLUMN country.tel_pattern IS
'Phone number regular expression patterns by country/territory.';

CREATE FUNCTION generate_postal_code_validator()
        RETURNS trigger LANGUAGE plpgsql AS $$
  DECLARE
    when_statements text;
  BEGIN
    WITH pc AS (
      SELECT CASE WHEN count(alpha_3_code) = 1 THEN
                    'WHEN p_country_code = '''
                    || string_agg(alpha_3_code, '')
                    || ''' THEN p_postal_code ~ '''
                    || postal_code_pattern
                    || ''''
                  ELSE
                    'WHEN p_country_code IN ('''
                    || string_agg(alpha_3_code, ''', ''')
                    || ''') THEN p_postal_code ~ '''
                    || postal_code_pattern
                    || ''''
             END AS when_statement
        FROM country
       WHERE postal_code_pattern IS NOT NULL
       GROUP BY postal_code_pattern
       ORDER BY array_agg(alpha_3_code) @> '{USA}' DESC
              , 1
    )
    SELECT E'CASE WHEN p_postal_code IS NULL OR p_country_code IS NULL THEN false\n             '
           || string_agg(pc.when_statement, E'\n             ')
           || E'\n             ELSE false\n        END;'
      INTO when_statements
      FROM pc
         ;

    EXECUTE format( 'CREATE FUNCTION is_postal_code( p_postal_code text
                                                              , p_country_code varchar(3) = ''USA''
                                                              )
                             RETURNS bool LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $dynamic$
                       SELECT %1$s
                     $dynamic$;'
                  , when_statements
                  );
    RETURN NULL; -- AFTER trigger, so no effect but a return statement still needed
  END;
$$;

  DROP TRIGGER IF EXISTS generate_postal_code_validator ON country;
CREATE TRIGGER generate_postal_code_validator
         AFTER INSERT
               OR UPDATE
               OR DELETE
            ON country
      FOR EACH STATEMENT
       EXECUTE PROCEDURE generate_postal_code_validator()
             ;

CREATE FUNCTION is_postal_code( p_postal_code  text
                                         , p_country_code varchar(3) = 'USA'
                                         )
        RETURNS bool LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
  SELECT false
         ;
$$; COMMENT ON FUNCTION is_postal_code(text, varchar) IS
'Validate postal code by country/territory.

Regexes from validator.js (https://www.npmjs.com/package/validator)';

CREATE FUNCTION is_postal_code( p_postal_code   text
                                         , p_country_codes varchar(3)[]
                                         )
        RETURNS bool LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE AS $$
  SELECT bool_or( is_postal_code( p_postal_code, codes.code ) )
    FROM unnest( p_country_codes ) AS codes( code )
       ;
$$; COMMENT ON FUNCTION is_postal_code(text, varchar[]) IS
'Validate postal code by a list of countries/territories.';

INSERT INTO country ( alpha_3_code
                    , alpha_2_code
                    , numeric_code
                    , name
                    , official_name
                    , tlds
                    , postal_code_pattern
                    , tel_pattern
                    )
     VALUES ( 'AFG', 'AF', '004', 'Afghanistan'                                         , 'The Islamic Republic of Afghanistan'                      , '{af}'   , NULL                                                                                                                     , NULL )
          , ( 'AGO', 'AO', '024', 'Angola'                                              , 'The Republic of Angola'                                   , '{ao}'   , NULL                                                                                                                     , NULL )
          , ( 'ALB', 'AL', '008', 'Albania'                                             , 'The Republic of Albania'                                  , '{al}'   , NULL                                                                                                                     , NULL )
          , ( 'AND', 'AD', '020', 'Andorra'                                             , 'The Principality of Andorra'                              , '{ad}'   , '^AD\d{3}$'                                                                                                              , NULL )
          , ( 'ARE', 'AE', '784', 'United Arab Emirates'                                , 'The United Arab Emirates'                                 , '{ae}'   , NULL                                                                                                                     , '^((\+?971)|0)?5[024568]\d{7}$' )
          , ( 'ARG', 'AR', '032', 'Argentina'                                           , 'The Argentine Republic'                                   , '{ar}'   , NULL                                                                                                                     , NULL )
          , ( 'ARM', 'AM', '051', 'Armenia'                                             , 'The Republic of Armenia'                                  , '{am}'   , NULL                                                                                                                     , NULL )
          , ( 'ATG', 'AG', '028', 'Antigua and Barbuda'                                 , 'Antigua and Barbuda'                                      , '{ag}'   , NULL                                                                                                                     , NULL )
          , ( 'AUS', 'AU', '036', 'Australia'                                           , 'The Commonwealth of Australia'                            , '{au}'   , '^\d{4}$'                                                                                                                , '^(\+?61|0)4\d{8}$' )
          , ( 'AUT', 'AT', '040', 'Austria'                                             , 'The Republic of Austria'                                  , '{at}'   , '^\d{4}$'                                                                                                                , '^(\+43|0)\d{1,4}\d{3,12}$' )
          , ( 'AZE', 'AZ', '031', 'Azerbaijan'                                          , 'The Republic of Azerbaijan'                               , '{az}'   , NULL                                                                                                                     , NULL )
          , ( 'BDI', 'BI', '108', 'Burundi'                                             , 'The Republic of Burundi'                                  , '{bi}'   , NULL                                                                                                                     , NULL )
          , ( 'BEL', 'BE', '056', 'Belgium'                                             , 'The Kingdom of Belgium'                                   , '{be}'   , '^\d{4}$'                                                                                                                , '^(\+?32|0)4?\d{8}$' )
          , ( 'BEN', 'BJ', '204', 'Benin'                                               , 'The Republic of Benin'                                    , '{bj}'   , NULL                                                                                                                     , NULL )
          , ( 'BFA', 'BF', '854', 'Burkina Faso'                                        , 'Burkina Faso'                                             , '{bf}'   , NULL                                                                                                                     , NULL )
          , ( 'BGD', 'BD', '050', 'Bangladesh'                                          , 'The People''s Republic of Bangladesh'                     , '{bd}'   , NULL                                                                                                                     , '^(\+?880|0)1[13456789][0-9]{8}$' )
          , ( 'BGR', 'BG', '100', 'Bulgaria'                                            , 'The Republic of Bulgaria'                                 , '{bg}'   , '^\d{4}$'                                                                                                                , '^(\+?359|0)?8[789]\d{7}$' )
          , ( 'BHR', 'BH', '048', 'Bahrain'                                             , 'The Kingdom of Bahrain'                                   , '{bh}'   , NULL                                                                                                                     , '^(\+?973)?(3|6)\d{7}$' )
          , ( 'BHS', 'BS', '044', 'Bahamas'                                             , 'The Commonwealth of The Bahamas'                          , '{bs}'   , NULL                                                                                                                     , NULL )
          , ( 'BIH', 'BA', '070', 'Bosnia and Herzegovina'                              , 'Bosnia and Herzegovina'                                   , '{ba}'   , NULL                                                                                                                     , NULL )
          , ( 'BLR', 'BY', '112', 'Belarus'                                             , 'The Republic of Belarus'                                  , '{by}'   , NULL                                                                                                                     , '^(\+?375)?(24|25|29|33|44)\d{7}$' )
          , ( 'BLZ', 'BZ', '084', 'Belize'                                              , 'Belize'                                                   , '{bz}'   , NULL                                                                                                                     , NULL )
          , ( 'BOL', 'BO', '068', 'Bolivia'                                             , 'The Plurinational State of Bolivia'                       , '{bo}'   , NULL                                                                                                                     , NULL )
          , ( 'BRA', 'BR', '076', 'Brazil'                                              , 'The Federative Republic of Brazil'                        , '{br}'   , '^\d{5}-\d{3}$'                                                                                                          , '(?=^(\+?55\-?|0)[1-9]{2}\-?\d{4}\-?\d{4}$)(^(\+?55\-?|0)[1-9]{2}\-?[6-9]\d{3}\-?\d{4}$)|(^(\+?55\-?|0)[1-9]{2}\-?9[6-9]\d{3}\-?\d{4}$)' )
          , ( 'BRB', 'BB', '052', 'Barbados'                                            , 'Barbados'                                                 , '{bb}'   , NULL                                                                                                                     , NULL )
          , ( 'BRN', 'BN', '096', 'Brunei Darussalam'                                   , 'The Nation of Brunei, the Abode of Peace'                 , '{bn}'   , NULL                                                                                                                     , NULL )
          , ( 'BTN', 'BT', '064', 'Bhutan'                                              , 'The Kingdom of Bhutan'                                    , '{bt}'   , NULL                                                                                                                     , NULL )
          , ( 'BWA', 'BW', '072', 'Botswana'                                            , 'The Republic of Botswana'                                 , '{bw}'   , NULL                                                                                                                     , NULL )
          , ( 'CAF', 'CF', '140', 'Central African Republic'                            , 'The Central African Republic'                             , '{cf}'   , NULL                                                                                                                     , NULL )
          , ( 'CAN', 'CA', '124', 'Canada'                                              , 'Canada'                                                   , '{ca}'   , '^[ABCEGHJKLMNPRSTVXYabceghjklmnprstvxy]\d[ABCEGHJ-NPRSTV-Zabceghj-nprstv-z][\s\-]?\d[ABCEGHJ-NPRSTV-Zabceghj-nprstv]\d$', NULL )
          , ( 'CHE', 'CH', '756', 'Switzerland'                                         , 'The Swiss Confederation'                                  , '{ch}'   , '^\d{4}$'                                                                                                                , NULL )
          , ( 'CHL', 'CL', '152', 'Chile'                                               , 'The Republic of Chile'                                    , '{cl}'   , NULL                                                                                                                     , '^(\+?56|0)[2-9]\d{1}\d{7}$' )
          , ( 'CHN', 'CN', '156', 'China'                                               , 'The People''s Republic of China'                          , '{cn}'   , NULL                                                                                                                     , '^((\+|00)86)?1([358][0-9]|4[579]|6[67]|7[0135678]|9[189])[0-9]{8}$' )
          , ( 'CIV', 'CI', '384', 'Côte d''Ivoire'                                      , 'The Republic of Côte d''Ivoire'                           , '{ci}'   , NULL                                                                                                                     , NULL )
          , ( 'CMR', 'CM', '120', 'Cameroon'                                            , 'The Republic of Cameroon'                                 , '{cm}'   , NULL                                                                                                                     , NULL )
          , ( 'COG', 'CG', '178', 'Congo'                                               , 'The Republic of the Congo'                                , '{cg}'   , NULL                                                                                                                     , NULL )
          , ( 'COL', 'CO', '170', 'Colombia'                                            , 'The Republic of Colombia'                                 , '{co}'   , NULL                                                                                                                     , NULL )
          , ( 'COM', 'KM', '174', 'Comoros'                                             , 'The Union of the Comoros'                                 , '{km}'   , NULL                                                                                                                     , NULL )
          , ( 'CPV', 'CV', '132', 'Cabo Verde'                                          , 'The Republic of Cabo Verde'                               , '{cv}'   , NULL                                                                                                                     , NULL )
          , ( 'CRI', 'CR', '188', 'Costa Rica'                                          , 'The Republic of Costa Rica'                               , '{cr}'   , NULL                                                                                                                     , NULL )
          , ( 'CUB', 'CU', '192', 'Cuba'                                                , 'The Republic of Cuba'                                     , '{cu}'   , NULL                                                                                                                     , NULL )
          , ( 'CYP', 'CY', '196', 'Cyprus'                                              , 'The Republic of Cyprus'                                   , '{cy}'   , NULL                                                                                                                     , NULL )
          , ( 'CZE', 'CZ', '203', 'Czechia'                                             , 'The Czech Republic'                                       , '{cz}'   , '^\d{3}\s?\d{2}$'                                                                                                        , '^(\+?420)? ?[1-9][0-9]{2} ?[0-9]{3} ?[0-9]{3}$' )
          , ( 'DEU', 'DE', '276', 'Germany'                                             , 'The Federal Republic of Germany'                          , '{de}'   , '^\d{5}$'                                                                                                                , '^(\+49)?0?1(5[0-25-9]\d|6([23]|0\d?)|7([0-57-9]|6\d))\d{7}$' )
          , ( 'DJI', 'DJ', '262', 'Djibouti'                                            , 'The Republic of Djibouti'                                 , '{dj}'   , NULL                                                                                                                     , NULL )
          , ( 'DMA', 'DM', '212', 'Dominica'                                            , 'The Commonwealth of Dominica'                             , '{dm}'   , NULL                                                                                                                     , NULL )
          , ( 'DNK', 'DK', '208', 'Denmark'                                             , 'The Kingdom of Denmark'                                   , '{dk}'   , '^\d{4}$'                                                                                                                , '^(\+?45)?\s?\d{2}\s?\d{2}\s?\d{2}\s?\d{2}$' )
          , ( 'DOM', 'DO', '214', 'Dominican Republic'                                  , 'The Dominican Republic'                                   , '{do}'   , NULL                                                                                                                     , NULL )
          , ( 'DZA', 'DZ', '012', 'Algeria'                                             , 'The People''s Democratic Republic of Algeria'             , '{dz}'   , '^\d{5}$'                                                                                                                , '^(\+?213|0)(5|6|7)\d{8}$' )
          , ( 'ECU', 'EC', '218', 'Ecuador'                                             , 'The Republic of Ecuador'                                  , '{ec}'   , NULL                                                                                                                     , NULL )
          , ( 'EGY', 'EG', '818', 'Egypt'                                               , 'The Arab Republic of Egypt'                               , '{eg}'   , NULL                                                                                                                     , '^((\+?20)|0)?1[0125]\d{8}$' )
          , ( 'ERI', 'ER', '232', 'Eritrea'                                             , 'The State of Eritrea'                                     , '{er}'   , NULL                                                                                                                     , NULL )
          , ( 'ESP', 'ES', '724', 'Spain'                                               , 'The Kingdom of Spain'                                     , '{es}'   , '^\d{5}$'                                                                                                                , '^(\+?34)?(6\d{1}|7[1234])\d{7}$' )
          , ( 'EST', 'EE', '233', 'Estonia'                                             , 'The Republic of Estonia'                                  , '{ee}'   , '^\d{5}$'                                                                                                                , '^(\+?372)?\s?(5|8[1-4])\s?([0-9]\s?){6,7}$' )
          , ( 'ETH', 'ET', '231', 'Ethiopia'                                            , 'The Federal Democratic Republic of Ethiopia'              , '{et}'   , NULL                                                                                                                     , NULL )
          , ( 'FIN', 'FI', '246', 'Finland'                                             , 'The Republic of Finland'                                  , '{fi}'   , '^\d{5}$'                                                                                                                , '^(\+?358|0)\s?(4(0|1|2|4|5|6)?|50)\s?(\d\s?){4,8}\d$' )
          , ( 'FJI', 'FJ', '242', 'Fiji'                                                , 'The Republic of Fiji'                                     , '{fj}'   , NULL                                                                                                                     , '^(\+?679)?\s?\d{3}\s?\d{4}$' )
          , ( 'FRA', 'FR', '250', 'France'                                              , 'The French Republic'                                      , '{fr}'   , '^\d{2}\s?\d{3}$'                                                                                                        , '^(\+?33|0)[67]\d{8}$' )
          , ( 'FSM', 'FM', '583', 'Micronesia'                                          , 'The Federated States of Micronesia'                       , '{fm}'   , NULL                                                                                                                     , NULL )
          , ( 'GAB', 'GA', '266', 'Gabon'                                               , 'The Gabonese Republic'                                    , '{ga}'   , NULL                                                                                                                     , NULL )
          , ( 'GBR', 'GB', '826', 'United Kingdom of Great Britain and Northern Ireland', 'The United Kingdom of Great Britain and Northern Ireland' , '{gb,uk}', '^([Gg][Ii][Rr]\s?0[Aa]{2}|[a-zA-Z]{1,2}\d[\da-zA-Z]?\s?(\d[a-zA-Z]{2})?)$'                                              , '^(\+?44|0)7\d{9}$' )
          , ( 'GEO', 'GE', '268', 'Georgia'                                             , 'Georgia'                                                  , '{ge}'   , NULL                                                                                                                     , NULL )
          , ( 'GHA', 'GH', '288', 'Ghana'                                               , 'The Republic of Ghana'                                    , '{gh}'   , NULL                                                                                                                     , '^(\+233|0)(20|50|24|54|27|57|26|56|23|28)\d{7}$' )
          , ( 'GIN', 'GN', '324', 'Guinea'                                              , 'The Republic of Guinea'                                   , '{gn}'   , NULL                                                                                                                     , NULL )
          , ( 'GMB', 'GM', '270', 'Gambia'                                              , 'The Republic of The Gambia'                               , '{gm}'   , NULL                                                                                                                     , NULL )
          , ( 'GNB', 'GW', '624', 'Guinea-Bissau'                                       , 'The Republic of Guinea-Bissau'                            , '{gw}'   , NULL                                                                                                                     , NULL )
          , ( 'GNQ', 'GQ', '226', 'Equatorial Guinea'                                   , 'The Republic of Equatorial Guinea'                        , '{gq}'   , NULL                                                                                                                     , NULL )
          , ( 'GRC', 'GR', '300', 'Greece'                                              , 'The Hellenic Republic'                                    , '{gr}'   , '^\d{3}\s?\d{2}$'                                                                                                        , '^(\+?30|0)?(69\d{8})$' )
          , ( 'GRD', 'GD', '308', 'Grenada'                                             , 'Grenada'                                                  , '{gd}'   , NULL                                                                                                                     , NULL )
          , ( 'GTM', 'GT', '320', 'Guatemala'                                           , 'The Republic of Guatemala'                                , '{gt}'   , NULL                                                                                                                     , NULL )
          , ( 'GUY', 'GY', '328', 'Guyana'                                              , 'The Co-operative Republic of Guyana'                      , '{gy}'   , NULL                                                                                                                     , NULL )
          , ( 'HND', 'HN', '340', 'Honduras'                                            , 'The Republic of Honduras'                                 , '{hn}'   , NULL                                                                                                                     , NULL )
          , ( 'HRV', 'HR', '191', 'Croatia'                                             , 'The Republic of Croatia'                                  , '{hr}'   , '^[1-5]\d{4}$'                                                                                                           , NULL )
          , ( 'HTI', 'HT', '332', 'Haiti'                                               , 'The Republic of Haiti'                                    , '{ht}'   , NULL                                                                                                                     , NULL )
          , ( 'HUN', 'HU', '348', 'Hungary'                                             , 'Hungary'                                                  , '{hu}'   , '^\d{4}$'                                                                                                                , '^(\+?36)(20|30|70)\d{7}$' )
          , ( 'IDN', 'ID', '360', 'Indonesia'                                           , 'The Republic of Indonesia'                                , '{id}'   , '^\d{5}$'                                                                                                                , '^(\+?62|0)8(1[123456789]|2[1238]|3[1238]|5[12356789]|7[78]|9[56789]|8[123456789])([\s?|\d]{5,11})$' )
          , ( 'IND', 'IN', '356', 'India'                                               , 'The Republic of India'                                    , '{in}'   , '^\d{6}$'                                                                                                                , '^(\+?91|0)?[6789]\d{9}$' )
          , ( 'IRL', 'IE', '372', 'Ireland'                                             , 'Ireland'                                                  , '{ie}'   , '^[a-zA-Z]\d[\d|w]\s\w{4}$'                                                                                              , '^(\+?353|0)8[356789]\d{7}$' )
          , ( 'IRN', 'IR', '364', 'Iran'                                                , 'The Islamic Republic of Iran'                             , '{ir}'   , NULL                                                                                                                     , '^(\+?98[\-\s]?|0)9[0-39]\d[\-\s]?\d{3}[\-\s]?\d{4}$' )
          , ( 'IRQ', 'IQ', '368', 'Iraq'                                                , 'The Republic of Iraq'                                     , '{iq}'   , NULL                                                                                                                     , '^(\+?964|0)?7[0-9]\d{8}$' )
          , ( 'ISL', 'IS', '352', 'Iceland'                                             , 'Iceland'                                                  , '{is}'   , '^\d{3}$'                                                                                                                , NULL )
          , ( 'ISR', 'IL', '376', 'Israel'                                              , 'The State of Israel'                                      , '{il}'   , '^\d{5}$'                                                                                                                , '^(\+972|0)([23489]|5[012345689]|77)[1-9]\d{6}$' )
          , ( 'ITA', 'IT', '380', 'Italy'                                               , 'The Italian Republic'                                     , '{it}'   , '^\d{5}$'                                                                                                                , '^(\+?39)?\s?3\d{2} ?\d{6,7}$' )
          , ( 'JAM', 'JM', '388', 'Jamaica'                                             , 'Jamaica'                                                  , '{jm}'   , NULL                                                                                                                     , NULL )
          , ( 'JOR', 'JO', '400', 'Jordan'                                              , 'The Hashemite Kingdom of Jordan'                          , '{jo}'   , NULL                                                                                                                     , '^(\+?962|0)?7[789]\d{7}$' )
          , ( 'JPN', 'JP', '392', 'Japan'                                               , 'Japan'                                                    , '{jp}'   , '^\d{3}\-\d{4}$'                                                                                                         , '^(\+81[ \-]?(\(0\))?|0)[6789]0[ \-]?\d{4}[ \-]?\d{4}$' )
          , ( 'KAZ', 'KZ', '398', 'Kazakhstan'                                          , 'The Republic of Kazakhstan'                               , '{kz}'   , NULL                                                                                                                     , '^(\+?7|8)?7\d{9}$' )
          , ( 'KEN', 'KE', '404', 'Kenya'                                               , 'The Republic of Kenya'                                    , '{ke}'   , '^\d{5}$'                                                                                                                , '^(\+?254|0)(7|1)\d{8}$' )
          , ( 'KGZ', 'KG', '417', 'Kyrgyzstan'                                          , 'The Kyrgyz Republic'                                      , '{kg}'   , NULL                                                                                                                     , NULL )
          , ( 'KHM', 'KH', '116', 'Cambodia'                                            , 'The Kingdom of Cambodia'                                  , '{kh}'   , NULL                                                                                                                     , NULL )
          , ( 'KIR', 'KI', '296', 'Kiribati'                                            , 'The Republic of Kiribati'                                 , '{ki}'   , NULL                                                                                                                     , NULL )
          , ( 'KNA', 'KN', '659', 'Saint Kitts and Nevis'                               , 'Saint Kitts and Nevis'                                    , '{kn}'   , NULL                                                                                                                     , NULL )
          , ( 'KOR', 'KR', '410', 'Korea'                                               , 'The Republic of Korea'                                    , '{kr}'   , NULL                                                                                                                     , '^((\+?82)[ \-]?)?0?1([0|1|6|7|8|9]{1})[ \-]?\d{3,4}[ \-]?\d{4}$' )
          , ( 'KWT', 'KW', '414', 'Kuwait'                                              , 'The State of Kuwait'                                      , '{kw}'   , NULL                                                                                                                     , '^(\+?965)[569]\d{7}$' )
          , ( 'LAO', 'LA', '418', 'Lao People''s Democratic Republic'                   , 'The Lao People''s Democratic Republic'                    , '{la}'   , NULL                                                                                                                     , NULL )
          , ( 'LBN', 'LB', '422', 'Lebanon'                                             , 'The Lebanese Republic'                                    , '{lb}'   , NULL                                                                                                                     , NULL )
          , ( 'LBR', 'LR', '430', 'Liberia'                                             , 'The Republic of Liberia'                                  , '{lr}'   , NULL                                                                                                                     , NULL )
          , ( 'LBY', 'LY', '434', 'Libya'                                               , 'The State of Libya'                                       , '{ly}'   , NULL                                                                                                                     , NULL )
          , ( 'LCA', 'LC', '662', 'Saint Lucia'                                         , 'Saint Lucia'                                              , '{lc}'   , NULL                                                                                                                     , NULL )
          , ( 'LIE', 'LI', '438', 'Liechtenstein'                                       , 'The Principality of Liechtenstein'                        , '{li}'   , '^(948[5-9]|949[0-7])$'                                                                                                  , NULL )
          , ( 'LKA', 'LK', '144', 'Sri Lanka'                                           , 'The Democratic Socialist Republic of Sri Lanka'           , '{lk}'   , NULL                                                                                                                     , NULL )
          , ( 'LSO', 'LS', '426', 'Lesotho'                                             , 'The Kingdom of Lesotho'                                   , '{ls}'   , NULL                                                                                                                     , NULL )
          , ( 'LTU', 'LT', '440', 'Lithuania'                                           , 'The Republic of Lithuania'                                , '{lt}'   , '^LT\-\d{5}$'                                                                                                            , '^(\+370|8)\d{8}$' )
          , ( 'LUX', 'LU', '442', 'Luxembourg'                                          , 'The Grand Duchy of Luxembourg'                            , '{lu}'   , '^\d{4}$'                                                                                                                , NULL )
          , ( 'LVA', 'LV', '428', 'Latvia'                                              , 'The Republic of Latvia'                                   , '{lv}'   , '^LV\-\d{4}$'                                                                                                            , NULL )
          , ( 'MAR', 'MA', '504', 'Morocco'                                             , 'The Kingdom of Morocco'                                   , '{ma}'   , NULL                                                                                                                     , NULL )
          , ( 'MCO', 'MC', '492', 'Monaco'                                              , 'The Principality of Monaco'                               , '{mc}'   , NULL                                                                                                                     , NULL )
          , ( 'MDA', 'MD', '498', 'Moldova'                                             , 'The Republic of Moldova'                                  , '{md}'   , NULL                                                                                                                     , NULL )
          , ( 'MDG', 'MG', '450', 'Madagascar'                                          , 'The Republic of Madagascar'                               , '{mg}'   , NULL                                                                                                                     , NULL )
          , ( 'MDV', 'MV', '462', 'Maldives'                                            , 'The Republic of Maldives'                                 , '{mv}'   , NULL                                                                                                                     , NULL )
          , ( 'MEX', 'MX', '484', 'Mexico'                                              , 'The United Mexican States'                                , '{mx}'   , '^\d{5}$'                                                                                                                , '^(\+?52)?(1|01)?\d{10,11}$' )
          , ( 'MHL', 'MH', '584', 'Marshall Islands'                                    , 'The Republic of the Marshall Islands'                     , '{mh}'   , NULL                                                                                                                     , NULL )
          , ( 'MKD', 'MK', '807', 'North Macedonia'                                     , 'Republic of North Macedonia'                              , '{mk}'   , NULL                                                                                                                     , NULL )
          , ( 'MLI', 'ML', '466', 'Mali'                                                , 'The Republic of Mali'                                     , '{ml}'   , NULL                                                                                                                     , NULL )
          , ( 'MLT', 'MT', '470', 'Malta'                                               , 'The Republic of Malta'                                    , '{mt}'   , '^[A-Za-z]{3}\s{0,1}\d{4}$'                                                                                              , '^(\+?356|0)?(99|79|77|21|27|22|25)[0-9]{6}$' )
          , ( 'MMR', 'MM', '104', 'Myanmar'                                             , 'The Republic of the Union of Myanmar'                     , '{mm}'   , NULL                                                                                                                     , NULL )
          , ( 'MNE', 'ME', '499', 'Montenegro'                                          , 'Montenegro'                                               , '{me}'   , NULL                                                                                                                     , NULL )
          , ( 'MNG', 'MN', '496', 'Mongolia'                                            , 'The State of Mongolia'                                    , '{mn}'   , NULL                                                                                                                     , NULL )
          , ( 'MOZ', 'MZ', '508', 'Mozambique'                                          , 'The Republic of Mozambique'                               , '{mz}'   , NULL                                                                                                                     , NULL )
          , ( 'MRT', 'MR', '478', 'Mauritania'                                          , 'The Islamic Republic of Mauritania'                       , '{mr}'   , NULL                                                                                                                     , NULL )
          , ( 'MUS', 'MU', '480', 'Mauritius'                                           , 'The Republic of Mauritius'                                , '{mu}'   , NULL                                                                                                                     , '^(\+?230|0)?\d{8}$' )
          , ( 'MWI', 'MW', '454', 'Malawi'                                              , 'The Republic of Malawi'                                   , '{mw}'   , NULL                                                                                                                     , NULL )
          , ( 'MYS', 'MY', '458', 'Malaysia'                                            , 'Malaysia'                                                 , '{my}'   , NULL                                                                                                                     , '^(\+?6?01){1}(([0145]{1}(\-|\s)?\d{7,8})|([236789]{1}(\s|\-)?\d{7}))$' )
          , ( 'NAM', 'NA', '516', 'Namibia'                                             , 'The Republic of Namibia'                                  , '{na}'   , NULL                                                                                                                     , NULL )
          , ( 'NER', 'NE', '562', 'Niger'                                               , 'The Republic of the Niger'                                , '{ne}'   , NULL                                                                                                                     , NULL )
          , ( 'NGA', 'NG', '566', 'Nigeria'                                             , 'The Federal Republic of Nigeria'                          , '{ng}'   , NULL                                                                                                                     , '^(\+?234|0)?[789]\d{9}$' )
          , ( 'NIC', 'NI', '558', 'Nicaragua'                                           , 'The Republic of Nicaragua'                                , '{ni}'   , NULL                                                                                                                     , NULL )
          , ( 'NLD', 'NL', '528', 'Netherlands'                                         , 'The Kingdom of the Netherlands'                           , '{nl}'   , '^\d{4}\s?[a-zA-Z]{2}$'                                                                                                  , '^(\+?31|0)6?\d{8}$' )
          , ( 'NOR', 'NO', '578', 'Norway'                                              , 'The Kingdom of Norway'                                    , '{no}'   , '^\d{4}$'                                                                                                                , '^(\+?47)?[49]\d{7}$' )
          , ( 'NPL', 'NP', '524', 'Nepal'                                               , 'The Federal Democratic Republic of Nepal'                 , '{np}'   , NULL                                                                                                                     , NULL )
          , ( 'NRU', 'NR', '520', 'Nauru'                                               , 'The Republic of Nauru'                                    , '{nr}'   , NULL                                                                                                                     , NULL )
          , ( 'NZL', 'NZ', '554', 'New Zealand'                                         , 'New Zealand'                                              , '{nz}'   , '^\d{4}$'                                                                                                                , '^(\+?64|0)[28]\d{7,9}$' )
          , ( 'OMN', 'OM', '512', 'Oman'                                                , 'The Sultanate of Oman'                                    , '{om}'   , NULL                                                                                                                     , NULL )
          , ( 'PAK', 'PK', '586', 'Pakistan'                                            , 'The Islamic Republic of Pakistan'                         , '{pk}'   , NULL                                                                                                                     , '^((\+92)|(0092))-{0,1}\d{3}-{0,1}\d{7}$|^\d{11}$|^\d{4}-\d{7}$' )
          , ( 'PAN', 'PA', '591', 'Panama'                                              , 'The Republic of Panamá'                                   , '{pa}'   , NULL                                                                                                                     , '^(\+?507)\d{7,8}$' )
          , ( 'PER', 'PE', '604', 'Peru'                                                , 'The Republic of Perú'                                     , '{pe}'   , NULL                                                                                                                     , NULL )
          , ( 'PHL', 'PH', '608', 'Philippines'                                         , 'The Republic of the Philippines'                          , '{ph}'   , NULL                                                                                                                     , NULL )
          , ( 'PLW', 'PW', '585', 'Palau'                                               , 'The Republic of Palau'                                    , '{pw}'   , NULL                                                                                                                     , NULL )
          , ( 'PNG', 'PG', '598', 'Papua New Guinea'                                    , 'The Independent State of Papua New Guinea'                , '{pg}'   , NULL                                                                                                                     , NULL )
          , ( 'POL', 'PL', '616', 'Poland'                                              , 'The Republic of Poland'                                   , '{pl}'   , '^\d{2}\-\d{3}$'                                                                                                         , '^(\+?48)? ?[5-8]\d ?\d{3} ?\d{2} ?\d{2}$' )
          , ( 'PRT', 'PT', '620', 'Portugal'                                            , 'The Portuguese Republic'                                  , '{pt}'   , '^\d{4}\-\d{3}?$'                                                                                                        , '^(\+?351)?9[1236]\d{7}$' )
          , ( 'PRY', 'PY', '600', 'Paraguay'                                            , 'The Republic of Paraguay'                                 , '{py}'   , NULL                                                                                                                     , '^(\+?595|0)9[9876]\d{7}$' )
          , ( 'QAT', 'QA', '634', 'Qatar'                                               , 'The State of Qatar'                                       , '{qa}'   , NULL                                                                                                                     , NULL )
          , ( 'ROU', 'RO', '642', 'Romania'                                             , 'Romania'                                                  , '{ro}'   , '^\d{6}$'                                                                                                                , '^(\+?4?0)\s?7\d{2}(\/|\s|\.|\-)?\d{3}(\s|\.|\-)?\d{3}$' )
          , ( 'RUS', 'RU', '643', 'Russian Federation'                                  , 'The Russian Federation'                                   , '{ru}'   , '^\d{6}$'                                                                                                                , '^(\+?7|8)?9\d{9}$' )
          , ( 'RWA', 'RW', '646', 'Rwanda'                                              , 'The Republic of Rwanda'                                   , '{rw}'   , NULL                                                                                                                     , '^(\+?250|0)?[7]\d{8}$' )
          , ( 'SAU', 'SA', '682', 'Saudi Arabia'                                        , 'The Kingdom of Saudi Arabia'                              , '{sa}'   , '^\d{5}$'                                                                                                                , '^(!?(\+?966)|0)?5\d{8}$' )
          , ( 'SDN', 'SD', '729', 'Sudan'                                               , 'The Republic of the Sudan'                                , '{sd}'   , NULL                                                                                                                     , NULL )
          , ( 'SEN', 'SN', '686', 'Senegal'                                             , 'The Republic of Senegal'                                  , '{sn}'   , NULL                                                                                                                     , NULL )
          , ( 'SGP', 'SG', '702', 'Singapore'                                           , 'The Republic of Singapore'                                , '{sg}'   , NULL                                                                                                                     , '^(\+65)?[89]\d{7}$' )
          , ( 'SLB', 'SB', '090', 'Solomon Islands'                                     , 'The Solomon Islands'                                      , '{sb}'   , NULL                                                                                                                     , NULL )
          , ( 'SLE', 'SL', '694', 'Sierra Leone'                                        , 'The Republic of Sierra Leone'                             , '{sl}'   , NULL                                                                                                                     , NULL )
          , ( 'SLV', 'SV', '222', 'El Salvador'                                         , 'The Republic of El Salvador'                              , '{sv}'   , NULL                                                                                                                     , NULL )
          , ( 'SMR', 'SM', '674', 'San Marino'                                          , 'The Republic of San Marino'                               , '{sm}'   , NULL                                                                                                                     , NULL )
          , ( 'SOM', 'SO', '706', 'Somalia'                                             , 'The Federal Republic of Somalia'                          , '{so}'   , NULL                                                                                                                     , NULL )
          , ( 'SRB', 'RS', '688', 'Serbia'                                              , 'The Republic of Serbia'                                   , '{rs}'   , NULL                                                                                                                     , '^(\+3816|06)[- \d]{5,9}$' )
          , ( 'SSD', 'SS', '728', 'South Sudan'                                         , 'The Republic of South Sudan'                              , '{ss}'   , NULL                                                                                                                     , NULL )
          , ( 'STP', 'ST', '678', 'Sao Tome and Principe'                               , 'The Democratic Republic of São Tomé and Príncipe'         , '{st}'   , NULL                                                                                                                     , NULL )
          , ( 'SUR', 'SR', '740', 'Suriname'                                            , 'The Republic of Suriname'                                 , '{sr}'   , NULL                                                                                                                     , NULL )
          , ( 'SVK', 'SK', '703', 'Slovakia'                                            , 'The Slovak Republic'                                      , '{sk}'   , '^\d{3}\s?\d{2}$'                                                                                                        , '^(\+?421)? ?[1-9][0-9]{2} ?[0-9]{3} ?[0-9]{3}$' )
          , ( 'SVN', 'SI', '705', 'Slovenia'                                            , 'The Republic of Slovenia'                                 , '{si}'   , '^\d{4}$'                                                                                                                , '^(\+386\s?|0)(\d{1}\s?\d{3}\s?\d{2}\s?\d{2}|\d{2}\s?\d{3}\s?\d{3})$' )
          , ( 'SWE', 'SE', '752', 'Sweden'                                              , 'The Kingdom of Sweden'                                    , '{se}'   , '^[1-9]\d{2}\s?\d{2}$'                                                                                                   , '^(\+?46|0)[\s\-]?7[\s\-]?[02369]([\s\-]?\d){7}$' )
          , ( 'SWZ', 'SZ', '748', 'Eswatini'                                            , 'The Kingdom of Eswatini'                                  , '{sz}'   , NULL                                                                                                                     , NULL )
          , ( 'SYC', 'SC', '690', 'Seychelles'                                          , 'The Republic of Seychelles'                               , '{sc}'   , NULL                                                                                                                     , NULL )
          , ( 'SYR', 'SY', '760', 'Syria'                                               , 'The Syrian Arab Republic'                                 , '{sy}'   , NULL                                                                                                                     , '^(!?(\+?963)|0)?9\d{8}$' )
          , ( 'TCD', 'TD', '148', 'Chad'                                                , 'The Republic of Chad'                                     , '{td}'   , NULL                                                                                                                     , NULL )
          , ( 'TGO', 'TG', '768', 'Togo'                                                , 'The Togolese Republic'                                    , '{tg}'   , NULL                                                                                                                     , NULL )
          , ( 'THA', 'TH', '764', 'Thailand'                                            , 'The Kingdom of Thailand'                                  , '{th}'   , NULL                                                                                                                     , '^(\+66|66|0)\d{9}$' )
          , ( 'TJK', 'TJ', '762', 'Tajikistan'                                          , 'The Republic of Tajikistan'                               , '{tj}'   , NULL                                                                                                                     , NULL )
          , ( 'TKM', 'TM', '795', 'Turkmenistan'                                        , 'Turkmenistan'                                             , '{tm}'   , NULL                                                                                                                     , NULL )
          , ( 'TLS', 'TL', '626', 'Timor-Leste'                                         , 'The Democratic Republic of Timor-Leste'                   , '{tl}'   , NULL                                                                                                                     , NULL )
          , ( 'TON', 'TO', '776', 'Tonga'                                               , 'The Kingdom of Tonga'                                     , '{to}'   , NULL                                                                                                                     , NULL )
          , ( 'TTO', 'TT', '780', 'Trinidad and Tobago'                                 , 'The Republic of Trinidad and Tobago'                      , '{tt}'   , NULL                                                                                                                     , NULL )
          , ( 'TUN', 'TN', '788', 'Tunisia'                                             , 'The Republic of Tunisia'                                  , '{tn}'   , '^\d{4}$'                                                                                                                , '^(\+?216)?[2459]\d{7}$' )
          , ( 'TUR', 'TR', '792', 'Turkey'                                              , 'The Republic of Turkey'                                   , '{tr}'   , NULL                                                                                                                     , '^(\+?90|0)?5\d{9}$' )
          , ( 'TUV', 'TV', '798', 'Tuvalu'                                              , 'Tuvalu'                                                   , '{tv}'   , NULL                                                                                                                     , NULL )
          , ( 'TZA', 'TZ', '834', 'Tanzania, the United Republic of'                    , 'The United Republic of Tanzania'                          , '{tz}'   , NULL                                                                                                                     , '^(\+?255|0)?[67]\d{8}$' )
          , ( 'UGA', 'UG', '800', 'Uganda'                                              , 'The Republic of Uganda'                                   , '{ug}'   , NULL                                                                                                                     , '^(\+?256|0)?[7]\d{8}$' )
          , ( 'UKR', 'UA', '804', 'Ukraine'                                             , 'Ukraine'                                                  , '{ua}'   , '^\d{5}$'                                                                                                                , '^(\+?38|8)?0\d{9}$' )
          , ( 'URY', 'UY', '858', 'Uruguay'                                             , 'The Oriental Republic of Uruguay'                         , '{uy}'   , NULL                                                                                                                     , '^(\+598|0)9[1-9][\d]{6}$' )
          , ( 'USA', 'US', '840', 'United States of America'                            , 'The United States of America'                             , '{us}'   , '^\d{5}(-\d{4})?$'                                                                                                       , '^((\+1|1)?( |-)?)?(\([2-9][0-9]{2}\)|[2-9][0-9]{2})( |-)?([2-9][0-9]{2}( |-)?[0-9]{4})$' )
          , ( 'UZB', 'UZ', '860', 'Uzbekistan'                                          , 'The Republic of Uzbekistan'                               , '{uz}'   , NULL                                                                                                                     , NULL )
          , ( 'VCT', 'VC', '670', 'Saint Vincent and the Grenadines'                    , 'Saint Vincent and the Grenadines'                         , '{vc}'   , NULL                                                                                                                     , NULL )
          , ( 'VEN', 'VE', '862', 'Venezuela'                                           , 'The Bolivarian Republic of Venezuela'                     , '{ve}'   , NULL                                                                                                                     , NULL )
          , ( 'VNM', 'VN', '704', 'Viet Nam'                                            , 'The Socialist Republic of Viet Nam'                       , '{vn}'   , NULL                                                                                                                     , '^(\+?84|0)((3([2-9]))|(5([2689]))|(7([0|6-9]))|(8([1-6|89]))|(9([0-9])))([0-9]{7})$' )
          , ( 'VUT', 'VU', '548', 'Vanuatu'                                             , 'The Republic of Vanuatu'                                  , '{vu}'   , NULL                                                                                                                     , NULL )
          , ( 'WSM', 'WS', '882', 'Samoa'                                               , 'The Independent State of Samoa'                           , '{ws}'   , NULL                                                                                                                     , NULL )
          , ( 'YEM', 'YE', '887', 'Yemen'                                               , 'The Republic of Yemen'                                    , '{ye}'   , NULL                                                                                                                     , NULL )
          , ( 'ZAF', 'ZA', '710', 'South Africa'                                        , 'The Republic of South Africa'                             , '{za}'   , '^\d{4}$'                                                                                                                , '^(\+?27|0)\d{9}$' )
          , ( 'ZMB', 'ZM', '894', 'Zambia'                                              , 'The Republic of Zambia'                                   , '{zm}'   , '^\d{5}$'                                                                                                                , '^(\+?26)?09[567]\d{7}$' )
          , ( 'ZWE', 'ZW', '716', 'Zimbabwe'                                            , 'The Republic of Zimbabwe'                                 , '{zw}'   , NULL                                                                                                                     , NULL )
ON CONFLICT (alpha_3_code)
         DO UPDATE SET alpha_2_code        = EXCLUDED.alpha_2_code
                     , numeric_code        = EXCLUDED.numeric_code
                     , name                = EXCLUDED.name
                     , official_name       = EXCLUDED.official_name
                     , parent              = NULL
                     , sovereignty         = NULL
                     , tlds                = EXCLUDED.tlds
                     , postal_code_pattern = EXCLUDED.postal_code_pattern
                     , tel_pattern         = EXCLUDED.tel_pattern
                     , recognized          = '(-infinity, infinity)'
          ;

-- Outlier entries
INSERT INTO country ( alpha_3_code
                    , alpha_2_code
                    , numeric_code
                    , name
                    , official_name
                    , sovereignty
                    , tlds
                    , postal_code_pattern
                    , tel_pattern
                    )
     VALUES ( 'ATA', 'AQ', '010', 'Antarctica'         , 'All land and ice shelves south of the 60th parallel south', 'Antarctic Treaty', '{aq}'   , NULL             , NULL )
          , ( 'ESH', 'EH', '732', 'Western Sahara'     , 'The Sahrawi Arab Democratic Republic'                     , 'disputed'        , NULL     , NULL             , NULL )
          , ( 'GGY', 'GG', '831', 'Guernsey'           , 'The Bailiwick of Guernsey'                                , 'British Crown'   , '{gg}'   , NULL             , '^(\+?44|0)1481\d{6}$' )
          , ( 'IMN', 'IM', '833', 'Isle of Man'        , 'The Isle of Man'                                          , 'British Crown'   , '{im}'   , NULL             , NULL )
          , ( 'JEY', 'JE', '832', 'Jersey'             , 'The Bailiwick of Jersey'                                  , 'British Crown'   , '{je}'   , NULL             , NULL )
          , ( 'PSE', 'PS', '275', 'Palestine, State of', 'The State of Palestine'                                   , 'UN observer'     , '{ps}'   , NULL             , NULL )
          , ( 'TWN', 'TW', '158', 'Taiwan'             , 'The Republic of China'                                    , 'disputed'        , '{tw}'   , '^\d{3}(\d{2})?$', '^(\+?886\-?|0)?9\d{8}$' )
          , ( 'VAT', 'VA', '336', 'Holy See'           , 'The Holy See'                                             , 'UN observer'     , '{va}'   , NULL             , NULL )
ON CONFLICT (alpha_3_code)
         DO UPDATE SET alpha_2_code        = EXCLUDED.alpha_2_code
                     , numeric_code        = EXCLUDED.numeric_code
                     , name                = EXCLUDED.name
                     , official_name       = EXCLUDED.official_name
                     , parent              = NULL
                     , sovereignty         = EXCLUDED.sovereignty
                     , tlds                = EXCLUDED.tlds
                     , postal_code_pattern = EXCLUDED.postal_code_pattern
                     , tel_pattern         = EXCLUDED.tel_pattern
                     , recognized          = '(-infinity, infinity)'
          ;

-- Territories (last so that the "parent" foreign key constraints resolve correctly
INSERT INTO country ( alpha_3_code
                    , alpha_2_code
                    , numeric_code
                    , name
                    , official_name
                    , parent
                    , tlds
                    , postal_code_pattern
                    , tel_pattern
                    )
     VALUES ( 'ABW', 'AW', '533', 'Aruba'                                         , 'Aruba'                                                 , 'NLD', '{aw}'   , NULL                        , NULL )
          , ( 'AIA', 'AI', '660', 'Anguilla'                                      , 'Anguilla'                                              , 'GBR', '{ai}'   , NULL                        , NULL )
          , ( 'ALA', 'AX', '248', 'Åland Islands'                                 , 'Åland'                                                 , 'FIN', '{ax}'   , NULL                        , NULL )
          , ( 'ASM', 'AS', '016', 'American Samoa'                                , 'The Territory of American Samoa'                       , 'USA', '{as}'   , '^\d{5}(-\d{4})?$'          , '^((\+1|1)?( |-)?)?(\([2-9][0-9]{2}\)|[2-9][0-9]{2})( |-)?([2-9][0-9]{2}( |-)?[0-9]{4})$' )
          , ( 'ATF', 'TF', '260', 'French Southern Territories'                   , 'The French Southern and Antarctic Lands'               , 'FRA', '{tf}'   , NULL                        , NULL )
          , ( 'BES', 'BQ', '535', 'Bonaire Sint Eustatius Saba'                   , 'Bonaire, Sint Eustatius and Saba'                      , 'NLD', '{bq,nl}', NULL                        , NULL )
          , ( 'BLM', 'BL', '652', 'Saint Barthélemy'                              , 'The Collectivity of Saint-Barthélemy'                  , 'FRA', '{bl}'   , NULL                        , NULL )
          , ( 'BMU', 'BM', '060', 'Bermuda'                                       , 'Bermuda'                                               , 'GBR', '{bm}'   , NULL                        , NULL )
          , ( 'BVT', 'BV', '074', 'Bouvet Island'                                 , 'Bouvet Island'                                         , 'NOR', NULL     , NULL                        , NULL )
          , ( 'CCK', 'CC', '166', 'Cocos'                                         , 'The Territory of Cocos (Keeling) Islands'              , 'AUS', '{cc}'   , NULL                        , NULL )
          , ( 'COK', 'CK', '184', 'Cook Islands'                                  , 'The Cook Islands'                                      , 'NZL', '{ck}'   , NULL                        , NULL )
          , ( 'CUW', 'CW', '531', 'Curaçao'                                       , 'The Country of Curaçao'                                , 'NLD', '{cw}'   , NULL                        , NULL )
          , ( 'CXR', 'CX', '162', 'Christmas Island'                              , 'The Territory of Christmas Island'                     , 'AUS', '{cx}'   , NULL                        , NULL )
          , ( 'CYM', 'KY', '136', 'Cayman Islands'                                , 'The Cayman Islands'                                    , 'GBR', '{ky}'   , NULL                        , NULL )
          , ( 'FLK', 'FK', '238', 'Falkland Islands'                              , 'The Falkland Islands'                                  , 'GBR', '{fk}'   , NULL                        , NULL )
          , ( 'FRO', 'FO', '234', 'Faroe Islands'                                 , 'The Faroe Islands'                                     , 'DNK', '{fo}'   , NULL                        , '^(\+?298)?\s?\d{2}\s?\d{2}\s?\d{2}$' )
          , ( 'GIB', 'GI', '292', 'Gibraltar'                                     , 'Gibraltar'                                             , 'GBR', '{gi}'   , NULL                        , NULL )
          , ( 'GLP', 'GP', '312', 'Guadeloupe'                                    , 'Guadeloupe'                                            , 'FRA', '{gp}'   , NULL                        , '^(\+?590|0|00590)[67]\d{8}$' )
          , ( 'GRL', 'GL', '304', 'Greenland'                                     , 'Kalaallit Nunaat'                                      , 'DNK', '{gl}'   , NULL                        , '^(\+?299)?\s?\d{2}\s?\d{2}\s?\d{2}$' )
          , ( 'GUF', 'GF', '254', 'French Guiana'                                 , 'Guyane'                                                , 'FRA', '{gf}'   , NULL                        , '^(\+?594|0|00594)[67]\d{8}$' )
          , ( 'GUM', 'GU', '316', 'Guam'                                          , 'The Territory of Guam'                                 , 'USA', '{gu}'   , '^\d{5}(-\d{4})?$'          , '^((\+1|1)?( |-)?)?(\([2-9][0-9]{2}\)|[2-9][0-9]{2})( |-)?([2-9][0-9]{2}( |-)?[0-9]{4})$' )
          , ( 'HKG', 'HK', '344', 'Hong Kong'                                     , 'The Hong Kong Special Administrative Region of China'  , 'CHN', '{hk}'   , NULL                        , '^(\+?852\-?)?[456789]\d{3}\-?\d{4}$' )
          , ( 'HMD', 'HM', '334', 'Heard Island and McDonald Islands'             , 'The Territory of Heard Island and McDonald Islands'    , 'AUS', '{hm}'   , NULL                        , NULL )
          , ( 'IOT', 'IO', '086', 'British Indian Ocean Territory'                , 'The British Indian Ocean Territory'                    , 'GBR', '{io}'   , NULL                        , NULL )
          , ( 'MAC', 'MO', '446', 'Macao'                                         , 'Macao Special Administrative Region of China'          , 'CHN', '{mo}'   , NULL                        , NULL )
          , ( 'MAF', 'MF', '663', 'Saint Martin'                                  , 'The Collectivity of Saint-Martin'                      , 'FRA', '{mf}'   , NULL                        , NULL )
          , ( 'MNP', 'MP', '580', 'Northern Mariana Islands'                      , 'The Commonwealth of the Northern Mariana Islands'      , 'USA', '{mp}'   , '^\d{5}(-\d{4})?$'          , '^((\+1|1)?( |-)?)?(\([2-9][0-9]{2}\)|[2-9][0-9]{2})( |-)?([2-9][0-9]{2}( |-)?[0-9]{4})$' )
          , ( 'MSR', 'MS', '500', 'Montserrat'                                    , 'Montserrat'                                            , 'GBR', '{ms}'   , NULL                        , NULL )
          , ( 'MTQ', 'MQ', '474', 'Martinique'                                    , 'Martinique'                                            , 'FRA', '{mq}'   , NULL                        , '^(\+?596|0|00596)[67]\d{8}$' )
          , ( 'MYT', 'YT', '175', 'Mayotte'                                       , 'The Department of Mayotte'                             , 'FRA', '{yt}'   , NULL                        , NULL )
          , ( 'NCL', 'NC', '540', 'New Caledonia'                                 , 'New Caledonia'                                         , 'FRA', '{nc}'   , NULL                        , NULL )
          , ( 'NFK', 'NF', '574', 'Norfolk Island'                                , 'The Territory of Norfolk Island'                       , 'AUS', '{nf}'   , NULL                        , NULL )
          , ( 'NIU', 'NU', '570', 'Niue'                                          , 'Niue'                                                  , 'NZL', '{nu}'   , NULL                        , NULL )
          , ( 'PCN', 'PN', '612', 'Pitcairn'                                      , 'The Pitcairn, Henderson, Ducie and Oeno Islands'       , 'GBR', '{pn}'   , NULL                        , NULL )
          , ( 'PRI', 'PR', '630', 'Puerto Rico'                                   , 'The Commonwealth of Puerto Rico'                       , 'USA', '{pr}'   , '^00[679]\d{2}([ -]\d{4})?$', '^((\+1|1)?( |-)?)?(\([2-9][0-9]{2}\)|[2-9][0-9]{2})( |-)?([2-9][0-9]{2}( |-)?[0-9]{4})$' )
          , ( 'PYF', 'PF', '258', 'French Polynesia'                              , 'French Polynesia'                                      , 'FRA', '{pf}'   , NULL                        , NULL )
          , ( 'REU', 'RE', '638', 'Réunion'                                       , 'Réunion'                                               , 'FRA', '{re}'   , NULL                        , '^(\+?262|0|00262)[67]\d{8}$' )
          , ( 'SGS', 'GS', '239', 'South Georgia and the South Sandwich Islands'  , 'South Georgia and the South Sandwich Islands'          , 'GBR', '{gs}'   , NULL                        , NULL )
          , ( 'SHN', 'SH', '654', 'Saint Helena Ascension Island Tristan da Cunha', 'Saint Helena, Ascension and Tristan da Cunha'          , 'GBR', '{sh}'   , NULL                        , NULL )
          , ( 'SJM', 'SJ', '744', 'Svalbard Jan Mayen'                            , 'Svalbard and Jan Mayen'                                , 'NOR', NULL     , NULL                        , NULL )
          , ( 'SPM', 'PM', '666', 'Saint Pierre and Miquelon'                     , 'The Overseas Collectivity of Saint-Pierre and Miquelon', 'FRA', '{pm}'   , NULL                        , NULL )
          , ( 'SXM', 'SX', '534', 'Sint Maarten'                                  , 'Sint Maarten'                                          , 'NLD', '{sx}'   , NULL                        , NULL )
          , ( 'TCA', 'TC', '796', 'Turks and Caicos Islands'                      , 'The Turks and Caicos Islands'                          , 'GBR', '{tc}'   , NULL                        , NULL )
          , ( 'TKL', 'TK', '772', 'Tokelau'                                       , 'Tokelau'                                               , 'NZL', '{tk}'   , NULL                        , NULL )
          , ( 'VIR', 'VI', '850', 'Virgin Islands'                                , 'The Virgin Islands of the United States'               , 'USA', '{vi}'   , '^008\d{2}([ -]\d{4})?$'    , '^((\+1|1)?( |-)?)?(\([2-9][0-9]{2}\)|[2-9][0-9]{2})( |-)?([2-9][0-9]{2}( |-)?[0-9]{4})$' )
          , ( 'WLF', 'WF', '876', 'Wallis and Futuna'                             , 'The Territory of the Wallis and Futuna Islands'        , 'FRA', '{wf}'   , NULL                        , NULL )
          -- Outsized territory entries
          , ( 'UMI', 'UM', '581', 'United States Minor Outlying Islands', 'Baker Island, Howland Island, Jarvis Island, Johnston Atoll, Kingman Reef, Midway Atoll, Navassa Island, Palmyra Atoll, and Wake Island', 'USA', NULL, '^\d{5}(-\d{4})?$', '^((\+1|1)?( |-)?)?(\([2-9][0-9]{2}\)|[2-9][0-9]{2})( |-)?([2-9][0-9]{2}( |-)?[0-9]{4})$' )
ON CONFLICT (alpha_3_code)
         DO UPDATE SET alpha_2_code        = EXCLUDED.alpha_2_code
                     , numeric_code        = EXCLUDED.numeric_code
                     , name                = EXCLUDED.name
                     , official_name       = EXCLUDED.official_name
                     , parent              = EXCLUDED.parent
                     , sovereignty         = NULL
                     , tlds                = EXCLUDED.tlds
                     , postal_code_pattern = EXCLUDED.postal_code_pattern
                     , tel_pattern         = EXCLUDED.tel_pattern
                     , recognized          = '(-infinity, infinity)'
          ;

RESET search_path;

COMMIT;
