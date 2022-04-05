-- Deploy geekspeak:stdlib_currency to pg
-- requires: stdlib_config_system_versioning

BEGIN;

-- Make sure everything we create here is put into the stdlib namespace
SET search_path = stdlib, public;

CREATE TABLE currency (
       alpha_3_code varchar(3) PRIMARY KEY
                    CHECK (alpha_3_code ~ '^[A-Z]{3}$')
,      numeric_code varchar(3) UNIQUE
                    CHECK (numeric_code ~ '^\d{3}$')
,              name text NOT NULL UNIQUE
                    CHECK (length_in(name, 1, 126))
, fractional_digits int2
,            active tstzrange NOT NULL
                    DEFAULT '(-infinity, infinity)'
,       replaced_by varchar(3)
                    CHECK (replaced_by ~ '^[A-Z]{3}$')
                    REFERENCES currency (alpha_3_code)
                            ON UPDATE CASCADE
                            ON DELETE SET NULL
,              LIKE stdlib.SYSTEM_VERSIONED
                    INCLUDING COMMENTS
); COMMENT ON TABLE currency IS
'ISO-4217 currencies.'
;
COMMENT ON COLUMN currency.alpha_3_code IS
'ISO-4217 3-character currency code.'
;
COMMENT ON COLUMN currency.numeric_code IS
'ISO-4217 3-digit numeric currency code. Prefer the 3-character code
in alpha_3_code when possible.'
;
COMMENT ON COLUMN currency.name IS
'ISO-4217 currency name.'
;
COMMENT ON COLUMN currency.fractional_digits IS
'How many digits should appear after the decimal separator for the currency.'
;
COMMENT ON COLUMN currency.active IS
'When this currency was in use.'
;
COMMENT ON COLUMN currency.replaced_by IS
'If this currency is no longer in use, a reference to the currency that
supplanted it.'
;

INSERT INTO currency( alpha_3_code
                    , numeric_code
                    , fractional_digits
                    , name
                    )
     VALUES ( 'AED', '784', 2   , 'United Arab Emirates dirham' )
          , ( 'AFN', '971', 2   , 'Afghan afghani' )
          , ( 'ALL', '008', 2   , 'Albanian lek' )
          , ( 'AMD', '051', 2   , 'Armenian dram' )
          , ( 'ANG', '532', 2   , 'Netherlands Antillean guilder' )
          , ( 'AOA', '973', 2   , 'Angolan kwanza' )
          , ( 'ARS', '032', 2   , 'Argentine peso' )
          , ( 'AUD', '036', 2   , 'Australian dollar' )
          , ( 'AWG', '533', 2   , 'Aruban florin' )
          , ( 'AZN', '944', 2   , 'Azerbaijani manat' )
          , ( 'BAM', '977', 2   , 'Bosnia and Herzegovina convertible mark' )
          , ( 'BBD', '052', 2   , 'Barbados dollar' )
          , ( 'BDT', '050', 2   , 'Bangladeshi taka' )
          , ( 'BGN', '975', 2   , 'Bulgarian lev' )
          , ( 'BHD', '048', 3   , 'Bahraini dinar' )
          , ( 'BIF', '108', 0   , 'Burundian franc' )
          , ( 'BMD', '060', 2   , 'Bermudian dollar' )
          , ( 'BND', '096', 2   , 'Brunei dollar' )
          , ( 'BOB', '068', 2   , 'Boliviano' )
          , ( 'BOV', '984', 2   , 'Bolivian Mvdol (funds code)' )
          , ( 'BRL', '986', 2   , 'Brazilian real' )
          , ( 'BSD', '044', 2   , 'Bahamian dollar' )
          , ( 'BTN', '064', 2   , 'Bhutanese ngultrum' )
          , ( 'BWP', '072', 2   , 'Botswana pula' )
          , ( 'BYN', '933', 2   , 'Belarusian ruble' )
          , ( 'BZD', '084', 2   , 'Belize dollar' )
          , ( 'CAD', '124', 2   , 'Canadian dollar' )
          , ( 'CDF', '976', 2   , 'Congolese franc' )
          , ( 'CHE', '947', 2   , 'WIR Euro (complementary currency)' )
          , ( 'CHF', '756', 2   , 'Swiss franc' )
          , ( 'CHW', '948', 2   , 'WIR Franc (complementary currency)' )
          , ( 'CLF', '990', 4   , 'Unidad de Fomento (funds code)' )
          , ( 'CLP', '152', 0   , 'Chilean peso' )
          , ( 'CNY', '156', 2   , 'Renminbi (Chinese) yuan' )
          , ( 'COP', '170', 2   , 'Colombian peso' )
          , ( 'COU', '970', 2   , 'Unidad de Valor Real (UVR) (funds code)' )
          , ( 'CRC', '188', 2   , 'Costa Rican colon' )
          , ( 'CUC', '931', 2   , 'Cuban convertible peso' )
          , ( 'CUP', '192', 2   , 'Cuban peso' )
          , ( 'CVE', '132', 2   , 'Cape Verdean escudo' )
          , ( 'CZK', '203', 2   , 'Czech koruna' )
          , ( 'DJF', '262', 0   , 'Djiboutian franc' )
          , ( 'DKK', '208', 2   , 'Danish krone' )
          , ( 'DOP', '214', 2   , 'Dominican peso' )
          , ( 'DZD', '012', 2   , 'Algerian dinar' )
          , ( 'EGP', '818', 2   , 'Egyptian pound' )
          , ( 'ERN', '232', 2   , 'Eritrean nakfa' )
          , ( 'ETB', '230', 2   , 'Ethiopian birr' )
          , ( 'EUR', '978', 2   , 'Euro' )
          , ( 'FJD', '242', 2   , 'Fiji dollar' )
          , ( 'FKP', '238', 2   , 'Falkland Islands pound' )
          , ( 'GBP', '826', 2   , 'Pound sterling' )
          , ( 'GEL', '981', 2   , 'Georgian lari' )
          , ( 'GHS', '936', 2   , 'Ghanaian cedi' )
          , ( 'GIP', '292', 2   , 'Gibraltar pound' )
          , ( 'GMD', '270', 2   , 'Gambian dalasi' )
          , ( 'GNF', '324', 0   , 'Guinean franc' )
          , ( 'GTQ', '320', 2   , 'Guatemalan quetzal' )
          , ( 'GYD', '328', 2   , 'Guyanese dollar' )
          , ( 'HKD', '344', 2   , 'Hong Kong dollar' )
          , ( 'HNL', '340', 2   , 'Honduran lempira' )
          , ( 'HRK', '191', 2   , 'Croatian kuna' )
          , ( 'HTG', '332', 2   , 'Haitian gourde' )
          , ( 'HUF', '348', 2   , 'Hungarian forint' )
          , ( 'IDR', '360', 2   , 'Indonesian rupiah' )
          , ( 'ILS', '376', 2   , 'Israeli new shekel' )
          , ( 'INR', '356', 2   , 'Indian rupee' )
          , ( 'IQD', '368', 3   , 'Iraqi dinar' )
          , ( 'IRR', '364', 2   , 'Iranian rial' )
          , ( 'ISK', '352', 0   , 'Icelandic króna' )
          , ( 'JMD', '388', 2   , 'Jamaican dollar' )
          , ( 'JOD', '400', 3   , 'Jordanian dinar' )
          , ( 'JPY', '392', 0   , 'Japanese yen' )
          , ( 'KES', '404', 2   , 'Kenyan shilling' )
          , ( 'KGS', '417', 2   , 'Kyrgyzstani som' )
          , ( 'KHR', '116', 2   , 'Cambodian riel' )
          , ( 'KMF', '174', 0   , 'Comoro franc' )
          , ( 'KPW', '408', 2   , 'North Korean won' )
          , ( 'KRW', '410', 0   , 'South Korean won' )
          , ( 'KWD', '414', 3   , 'Kuwaiti dinar' )
          , ( 'KYD', '136', 2   , 'Cayman Islands dollar' )
          , ( 'KZT', '398', 2   , 'Kazakhstani tenge' )
          , ( 'LAK', '418', 2   , 'Lao kip' )
          , ( 'LBP', '422', 2   , 'Lebanese pound' )
          , ( 'LKR', '144', 2   , 'Sri Lankan rupee' )
          , ( 'LRD', '430', 2   , 'Liberian dollar' )
          , ( 'LSL', '426', 2   , 'Lesotho loti' )
          , ( 'LYD', '434', 3   , 'Libyan dinar' )
          , ( 'MAD', '504', 2   , 'Moroccan dirham' )
          , ( 'MDL', '498', 2   , 'Moldovan leu' )
          , ( 'MGA', '969', 2   , 'Malagasy ariary' )
          , ( 'MKD', '807', 2   , 'Macedonian denar' )
          , ( 'MMK', '104', 2   , 'Myanmar kyat' )
          , ( 'MNT', '496', 2   , 'Mongolian tögrög' )
          , ( 'MOP', '446', 2   , 'Macanese pataca' )
          , ( 'MRU', '929', 2   , 'Mauritanian ouguiya' )
          , ( 'MUR', '480', 2   , 'Mauritian rupee' )
          , ( 'MVR', '462', 2   , 'Maldivian rufiyaa' )
          , ( 'MWK', '454', 2   , 'Malawian kwacha' )
          , ( 'MXN', '484', 2   , 'Mexican peso' )
          , ( 'MXV', '979', 2   , 'Mexican Unidad de Inversion (UDI) (funds code)' )
          , ( 'MYR', '458', 2   , 'Malaysian ringgit' )
          , ( 'MZN', '943', 2   , 'Mozambican metical' )
          , ( 'NAD', '516', 2   , 'Namibian dollar' )
          , ( 'NGN', '566', 2   , 'Nigerian naira' )
          , ( 'NIO', '558', 2   , 'Nicaraguan córdoba' )
          , ( 'NOK', '578', 2   , 'Norwegian krone' )
          , ( 'NPR', '524', 2   , 'Nepalese rupee' )
          , ( 'NZD', '554', 2   , 'New Zealand dollar' )
          , ( 'OMR', '512', 3   , 'Omani rial' )
          , ( 'PAB', '590', 2   , 'Panamanian balboa' )
          , ( 'PEN', '604', 2   , 'Peruvian sol' )
          , ( 'PGK', '598', 2   , 'Papua New Guinean kina' )
          , ( 'PHP', '608', 2   , 'Philippine peso' )
          , ( 'PKR', '586', 2   , 'Pakistani rupee' )
          , ( 'PLN', '985', 2   , 'Polish złoty' )
          , ( 'PYG', '600', 0   , 'Paraguayan guaraní' )
          , ( 'QAR', '634', 2   , 'Qatari riyal' )
          , ( 'RON', '946', 2   , 'Romanian leu' )
          , ( 'RSD', '941', 2   , 'Serbian dinar' )
          , ( 'RUB', '643', 2   , 'Russian ruble' )
          , ( 'RWF', '646', 0   , 'Rwandan franc' )
          , ( 'SAR', '682', 2   , 'Saudi riyal' )
          , ( 'SBD', '090', 2   , 'Solomon Islands dollar' )
          , ( 'SCR', '690', 2   , 'Seychelles rupee' )
          , ( 'SDG', '938', 2   , 'Sudanese pound' )
          , ( 'SEK', '752', 2   , 'Swedish krona/kronor' )
          , ( 'SGD', '702', 2   , 'Singapore dollar' )
          , ( 'SHP', '654', 2   , 'Saint Helena pound' )
          , ( 'SLL', '694', 2   , 'Sierra Leonean leone' )
          , ( 'SOS', '706', 2   , 'Somali shilling' )
          , ( 'SRD', '968', 2   , 'Surinamese dollar' )
          , ( 'SSP', '728', 2   , 'South Sudanese pound' )
          , ( 'STN', '930', 2   , 'São Tomé and Príncipe dobra' )
          , ( 'SVC', '222', 2   , 'Salvadoran colón' )
          , ( 'SYP', '760', 2   , 'Syrian pound' )
          , ( 'SZL', '748', 2   , 'Swazi lilangeni' )
          , ( 'THB', '764', 2   , 'Thai baht' )
          , ( 'TJS', '972', 2   , 'Tajikistani somoni' )
          , ( 'TMT', '934', 2   , 'Turkmenistan manat' )
          , ( 'TND', '788', 3   , 'Tunisian dinar' )
          , ( 'TOP', '776', 2   , 'Tongan paʻanga' )
          , ( 'TRY', '949', 2   , 'Turkish lira' )
          , ( 'TTD', '780', 2   , 'Trinidad and Tobago dollar' )
          , ( 'TWD', '901', 2   , 'New Taiwan dollar' )
          , ( 'TZS', '834', 2   , 'Tanzanian shilling' )
          , ( 'UAH', '980', 2   , 'Ukrainian hryvnia' )
          , ( 'UGX', '800', 0   , 'Ugandan shilling' )
          , ( 'USD', '840', 2   , 'United States dollar' )
          , ( 'USN', '997', 2   , 'United States dollar (next day) (funds code)' )
          , ( 'UYI', '940', 0   , 'Uruguay Peso en Unidades Indexadas (URUIURUI) (funds code)' )
          , ( 'UYU', '858', 2   , 'Uruguayan peso' )
          , ( 'UYW', '927', 4   , 'Unidad previsional' )
          , ( 'UZS', '860', 2   , 'Uzbekistan som' )
          , ( 'VES', '928', 2   , 'Venezuelan bolívar soberano' )
          , ( 'VND', '704', 0   , 'Vietnamese đồng' )
          , ( 'VUV', '548', 0   , 'Vanuatu vatu' )
          , ( 'WST', '882', 2   , 'Samoan tala' )
          , ( 'XAF', '950', 0   , 'CFA franc BEAC' )
          , ( 'XAG', '961', NULL, 'Silver (one troy ounce)' )
          , ( 'XAU', '959', NULL, 'Gold (one troy ounce)' )
          , ( 'XBA', '955', NULL, 'European Composite Unit (EURCO) (bond market unit)' )
          , ( 'XBB', '956', NULL, 'European Monetary Unit (E.M.U.-6) (bond market unit)' )
          , ( 'XBC', '957', NULL, 'European Unit of Account 9 (E.U.A.-9) (bond market unit)' )
          , ( 'XBD', '958', NULL, 'European Unit of Account 17 (E.U.A.-17) (bond market unit)' )
          , ( 'XCD', '951', 2   , 'East Caribbean dollar' )
          , ( 'XDR', '960', NULL, 'Special drawing rights' )
          , ( 'XOF', '952', 0   , 'CFA franc BCEAO' )
          , ( 'XPD', '964', NULL, 'Palladium (one troy ounce)' )
          , ( 'XPF', '953', 0   , 'CFP franc (franc Pacifique)' )
          , ( 'XPT', '962', NULL, 'Platinum (one troy ounce)' )
          , ( 'XSU', '994', NULL, 'SUCRE' )
          , ( 'XTS', '963', NULL, 'Code reserved for testing' )
          , ( 'XUA', '965', NULL, 'ADB Unit of Account' )
          , ( 'XXX', '999', NULL, 'No currency ' )
          , ( 'YER', '886', 2   , 'Yemeni rial' )
          , ( 'ZAR', '710', 2   , 'South African rand' )
          , ( 'ZMW', '967', 2   , 'Zambian kwacha' )
          , ( 'ZWL', '932', 2   , 'Zimbabwean dollar' )
         ON CONFLICT (alpha_3_code)
         DO UPDATE SET numeric_code      = EXCLUDED.numeric_code
                     , fractional_digits = EXCLUDED.fractional_digits
                     , name              = EXCLUDED.name
                     , active            = '(-infinity, infinity)'
                     , replaced_by       = NULL
;

-- Discontinued currencies
INSERT INTO currency( alpha_3_code
                    , numeric_code
                    , fractional_digits
                    , name
                    , active
                    , replaced_by
                    )
     VALUES ( 'ADF', NULL , 2   , 'Andorran franc'                                , '[1960-01-01, 1999-01-01)', 'EUR' )
          , ( 'ADP', '020', 0   , 'Andorran peseta'                               , '[1869-01-01, 1999-01-01)', 'EUR' )
          , ( 'AFA', '004', NULL, 'Afghan afghani (-2003)'                        , '[1925-01-01, 2003-01-01)', 'AFN' )
          , ( 'AOK', NULL , 0   , 'Angolan kwanza (-1990)'                        , '[1977-01-08, 1990-09-24)', 'AON' )
          , ( 'AON', '024', 0   , 'Angolan new kwanza'                            , '[1990-09-25, 1995-06-30)', 'AOR' )
          , ( 'AOR', '982', 0   , 'Angolan kwanza reajustado'                     , '[1995-07-01, 1999-11-30)', 'AOA' )
          , ( 'ARL', NULL , 2   , 'Argentine peso ley'                            , '[1970-01-01, 1983-05-05)', 'ARP' )
          , ( 'ARP', NULL , 2   , 'Argentine peso argentino'                      , '[1983-06-06, 1985-06-14)', 'ARA' )
          , ( 'ARA', NULL , 2   , 'Argentine austral'                             , '[1985-06-15, 1991-12-31)', 'ARS' )
          , ( 'ATS', '040', 2   , 'Austrian schilling'                            , '[1945-01-01, 1999-01-01)', 'EUR' )
          , ( 'AZM', '031', 0   , 'Azerbaijani manat (-2006)'                     , '[1992-08-15, 2006-01-01)', 'AZN' )
          , ( 'BAD', '070', 2   , 'Bosnia and Herzegovina dinar'                  , '[1992-07-01, 1998-02-04)', 'BAM' )
          , ( 'BEF', '056', 2   , 'Belgian franc'                                 , '[1832-01-01, 1999-01-01)', 'EUR' )
          , ( 'BGL', '100', 2   , 'Bulgarian lev (-1999)'                         , '[1962-01-01, 1999-08-31)', 'BGN' )
          , ( 'BOP', NULL , 2   , 'Bolivian peso'                                 , '[1963-01-01, 1987-01-01)', 'BOB' )
          , ( 'BRB', NULL , 2   , 'Brazilian cruzeiro (-1986)'                    , '[1970-01-01, 1986-02-28)', 'BRC' )
          , ( 'BRC', NULL , 2   , 'Brazilian cruzado'                             , '[1986-02-28, 1989-01-15)', 'BRN' )
          , ( 'BRN', NULL , 2   , 'Brazilian cruzado novo'                        , '[1989-01-16, 1990-03-15)', 'BRE' )
          , ( 'BRE', '076', 2   , 'Brazilian cruzeiro'                            , '[1990-03-15, 1993-08-01)', 'BRR' )
          , ( 'BRR', '987', 2   , 'Brazilian cruzeiro real'                       , '[1993-08-01, 1994-06-30)', 'BRL' )
          , ( 'BYB', '112', 2   , 'Belarusian ruble (-1999)'                      , '[1992-01-01, 1999-12-31)', 'BYR' )
          , ( 'BYR', '974', 0   , 'Belarusian ruble (-2016)'                      , '[2000-01-01, 2016-06-30)', 'BYN' )
          , ( 'CSD', '891', 2   , 'Serbian dinar (-2006)'                         , '[2003-07-03, 2006-06-19)', 'RSD' )
          , ( 'CSK', '200', NULL, 'Czechoslovak koruna'                           , '[1919-04-10, 1993-02-08)', 'CZK' )
          , ( 'CYP', '196', 2   , 'Cypriot pound'                                 , '[1879-01-01, 2006-01-01)', 'EUR' )
          , ( 'DDM', '278', NULL, 'East German mark'                              , '[1948-06-21, 1990-07-01)', 'DEM' )
          , ( 'DEM', '276', 2   , 'German mark'                                   , '[1948-01-01, 1999-01-01)', 'EUR' )
          , ( 'ECS', '218', 0   , 'Ecuadorian sucre'                              , '[1884-01-01, 2000-02-29)', 'USD' )
          , ( 'ECV', '983', NULL, 'Ecuador Unidad de Valor Constante (funds code)', '[1993-01-01, 2000-02-29)', NULL )
          , ( 'EEK', '233', 2   , 'Estonian kroon'                                , '[1992-01-01, 2010-01-01)', 'EUR' )
          , ( 'ESA', '996', NULL, 'Spanish peseta (account A)'                    , '[1978-01-01, 1981-01-01)', 'ESP' )
          , ( 'ESB', '995', NULL, 'Spanish peseta (account B)'                    , '[1981-01-01, 1994-12-01)', 'ESP' )
          , ( 'ESP', '724', 0   , 'Spanish peseta'                                , '[1869-01-01, 1999-01-01)', 'EUR' )
          , ( 'FIM', '246', 2   , 'Finnish markka'                                , '[1860-01-01, 1999-01-01)', 'EUR' )
          , ( 'FRF', '250', 2   , 'French franc'                                  , '[1960-01-01, 1999-01-01)', 'EUR' )
          , ( 'GNE', NULL , NULL, 'Guinean syli'                                  , '[1971-01-01, 1985-12-31)', 'GNF' )
          , ( 'GHC', '288', 0   , 'Ghanaian cedi (-2007)'                         , '[1967-01-01, 2007-07-01)', 'GHS' )
          , ( 'GQE', NULL , NULL, 'Equatorial Guinean ekwele'                     , '[1975-01-01, 1985-12-31)', 'XAF' )
          , ( 'GRD', '300', 2   , 'Greek drachma'                                 , '[1954-05-01, 2001-01-01)', 'EUR' )
          , ( 'GWP', '624', NULL, 'Guinea-Bissau peso'                            , '[1975-01-01, 1997-05-31)', 'XOF' )
          , ( 'HRD', NULL , NULL, 'Croatian dinar'                                , '[1991-12-23, 1994-05-30)', 'HRK' )
          , ( 'IEP', '372', 2   , 'Irish pound'                                   , '[1938-01-01, 1999-01-01)', 'EUR' )
          , ( 'ILP', NULL , 3   , 'Israeli lira'                                  , '[1948-01-01, 1980-02-20)', 'ILR' )
          , ( 'ILR', NULL , 2   , 'Israeli shekel'                                , '[1980-02-24, 1985-12-31)', 'ILS' )
          , ( 'ISJ', NULL , 2   , 'Icelandic old króna'                           , '[1922-01-01, 1981-06-30)', 'ISK' )
          , ( 'ITL', '380', 0   , 'Italian lira'                                  , '[1861-01-01, 1999-01-01)', 'EUR' )
          , ( 'LAJ', NULL , NULL, 'Lao kip (-1979)'                               , '[1965-01-01, 1979-12-31)', 'LAK' )
          , ( 'LTL', '440', 2   , 'Lithuanian litas'                              , '[1993-01-01, 2015-01-01)', 'EUR' )
          , ( 'LUF', '442', 2   , 'Luxembourg franc'                              , '[1944-01-01, 1999-01-01)', 'EUR' )
          , ( 'LVL', '428', 2   , 'Latvian lats'                                  , '[1992-01-01, 2013-01-01)', 'EUR' )
          , ( 'MAF', NULL , NULL, 'Moroccan franc'                                , '[1921-01-01, 1976-01-01)', 'MAD' )
          , ( 'MCF', NULL , 2   , 'Monegasque franc'                              , '[1960-01-01, 1995-03-31)', 'FRF' )
          , ( 'MGF', '450', 2   , 'Malagasy franc'                                , '[1963-07-01, 2005-01-01)', 'MGA' )
          , ( 'MKN', NULL , NULL, 'Old Macedonian denar'                          , '[1992-04-27, 1993-06-30)', 'MKD' )
          , ( 'MLF', '466', NULL, 'Malian franc'                                  , '[1962-01-01, 1984-01-01)', 'XOF' )
          , ( 'MVQ', NULL , NULL, 'Maldivian rupee'                               , '[-infinity , 1981-12-31)', 'MVR' )
          , ( 'MRO', '478', NULL, 'Mauritanian Ouguiya'                           , '[1973-06-29, 2018-01-01)', 'MRU' )
          , ( 'MXP', NULL , NULL, 'Mexican peso (-1993)'                          , '[1863-01-01, 1993-03-31)', 'MXN' )
          , ( 'MZM', '508', 0   , 'Mozambican metical (-2006)'                    , '[1980-01-01, 2006-06-30)', 'MZN' )
          , ( 'MTL', '470', 2   , 'Maltese lira'                                  , '[1972-05-26, 2006-01-01)', 'EUR' )
          , ( 'NIC', NULL , 2   , 'Nicaraguan córdoba (-1990)'                    , '[1988-01-01, 1990-10-31)', 'NIO' )
          , ( 'NLG', '528', 2   , 'Dutch guilder'                                 , '[1810-01-01, 1999-01-01)', 'EUR' )
          , ( 'PEH', NULL , NULL, 'Peruvian old sol'                              , '[1863-01-01, 1985-02-01)', 'PEI' )
          , ( 'PEI', NULL , NULL, 'Peruvian inti'                                 , '[1985-02-01, 1991-10-01)', 'PEN' )
          , ( 'PLZ', '616', NULL, 'Polish zloty'                                  , '[1950-10-30, 1994-12-31)', 'PLN' )
          , ( 'PTE', '620', 0   , 'Portuguese escudo'                             , '[1911-05-22, 1999-01-01)', 'EUR' )
          , ( 'ROL', '642', NULL, 'Romanian leu (-2005)'                          , '[1952-01-28, 2005-01-01)', 'RON' )
          , ( 'RUR', '810', 2   , 'Russian ruble (-1997)'                         , '[1992-01-01, 1997-12-31)', 'RUB' )
          , ( 'SDD', '736', NULL, 'Sudanese dinar'                                , '[1992-06-08, 2007-01-10)', 'SDG' )
          , ( 'SDP', NULL , NULL, 'Sudanese old pound'                            , '[1956-01-01, 1992-06-08)', 'SDD' )
          , ( 'SIT', '705', 2   , 'Slovenian tolar'                               , '[1991-10-08, 2005-01-01)', 'EUR' )
          , ( 'SKK', '703', 2   , 'Slovak koruna'                                 , '[1993-02-08, 2007-01-01)', 'EUR' )
          , ( 'SML', NULL , 0   , 'San Marinese lira'                             , '[1864-01-01, 1992-08-31)', 'ITL' )
          , ( 'SRG', '740', NULL, 'Suriname guilder'                              , '[1942-01-01, 2004-01-01)', 'SRD' )
          , ( 'STD', '678', NULL, 'São Tomé and Príncipe Dobra'                   , '[1977-01-01, 2018-04-01)', 'STN' )
          , ( 'SUR', NULL , NULL, 'Soviet Union ruble'                            , '[1961-01-01, 1991-12-26)', 'RUR' )
          , ( 'TJR', '762', NULL, 'Tajikistani ruble'                             , '[1995-05-10, 2000-10-30)', 'TJS' )
          , ( 'TMM', '795', 0   , 'Turkmenistani manat'                           , '[1993-11-01, 2008-12-31)', 'TMT' )
          , ( 'TPE', '626', NULL, 'Portuguese Timorese escudo'                    , '[1959-01-01, 1976-01-01)', 'USD' )
          , ( 'TRL', '792', 0   , 'Turkish lira (-2005)'                          , '[1843-01-01, 2005-12-31)', 'TRY' )
          , ( 'UAK', '804', NULL, 'Ukrainian karbovanets'                         , '[1992-10-01, 1996-09-01)', 'UAH' )
          , ( 'UGS', NULL , NULL, 'Ugandan shilling (-1987)'                      , '[1966-01-01, 1987-12-31)', 'UGX' )
          , ( 'USS', '998', 2   , 'United States dollar (same day) (funds code)'  , '[-infinity , 2014-03-28)', NULL )
          , ( 'UYP', NULL , NULL, 'Uruguay peso'                                  , '[1896-01-01, 1975-07-01)', 'UYN' )
          , ( 'UYN', NULL , NULL, 'Uruguay new peso'                              , '[1975-07-01, 1993-03-01)', 'UYU' )
          , ( 'VAL', NULL , 0   , 'Vatican lira'                                  , '[1929-01-01, 1994-12-31)', 'ITL' )
          , ( 'VEB', '862', 2   , 'Venezuelan bolívar'                            , '[1879-03-31, 2008-01-01)', 'VEF' )
          , ( 'VEF', '937', 2   , 'Venezuelan bolívar fuerte'                     , '[2008-01-01, 2018-08-20)', 'VES' )
          , ( 'XEU', '954', NULL, 'European Currency Unit'                        , '[1979-03-13, 1998-12-31)', 'EUR' )
          , ( 'XFO', NULL , NULL, 'Gold franc (special settlement currency)'      , '[1803-01-01, 2003-01-01)', 'XDR' )
          , ( 'XFU', NULL , NULL, 'UIC franc (special settlement currency)'       , '[1922-10-17, 2013-11-07)', 'EUR' )
          , ( 'YDD', '720', NULL, 'South Yemeni dinar'                            , '[1965-01-01, 1996-06-11)', 'YER' )
          , ( 'YUD', NULL , 2   , 'Yugoslav dinar (-1990)'                        , '[1966-01-01, 1989-12-31)', 'YUN' )
          , ( 'YUN', '890', 2   , 'Yugoslav dinar (1990-1992)'                    , '[1990-01-01, 1992-06-30)', 'YUR' )
          , ( 'YUR', NULL , 2   , 'Yugoslav dinar (1992-1993)'                    , '[1992-07-01, 1993-09-30)', 'YUO' )
          , ( 'YUO', NULL , 2   , 'Yugoslav dinar (1993)'                         , '[1993-10-01, 1993-12-31)', 'YUG' )
          , ( 'YUG', NULL , 2   , 'Yugoslav dinar (1994)'                         , '[1994-01-01, 1994-01-23)', 'YUM' )
          , ( 'YUM', NULL , 2   , 'Yugoslav dinar'                                , '[1994-01-24, 2003-07-02)', 'CSD' )
          , ( 'ZAL', '991', NULL, 'South African financial rand (funds code)'     , '[1985-09-01, 1995-03-13)', NULL )
          , ( 'ZMK', '894', 2   , 'Zambian kwacha (-2013)'                        , '[1968-01-16, 2013-01-01)', 'ZMW' )
          , ( 'ZRZ', NULL , 3   , 'Zairean zaire'                                 , '[1967-01-01, 1993-01-01)', 'ZRN' )
          , ( 'ZRN', '180', 2   , 'Zairean new zaire'                             , '[1993-01-01, 1997-01-01)', 'CDF' )
          , ( 'ZWC', NULL , 2   , 'Rhodesian dollar'                              , '[1970-02-17, 1980-01-01)', 'ZWD' )
          , ( 'ZWD', '716', 2   , 'Zimbabwean dollar (-2007)'                     , '[1980-04-18, 2006-07-31)', 'ZWN' )
          , ( 'ZWN', '942', 2   , 'Zimbabwean dollar (-2008)'                     , '[2006-08-01, 2008-07-31)', 'ZWR' )
          , ( 'ZWR', '935', 2   , 'Zimbabwean dollar (-2009)'                     , '[2008-08-01, 2009-02-02)', 'ZWL' )
          , ( 'ZWL', '932', 2   , 'Zimbabwean dollar (2009)'                      , '[2009-02-03, 2009-04-12)', 'USD' )
         ON CONFLICT (alpha_3_code)
         DO UPDATE SET numeric_code      = EXCLUDED.numeric_code
                     , fractional_digits = EXCLUDED.fractional_digits
                     , name              = EXCLUDED.name
                     , active            = EXCLUDED.active
                     , replaced_by       = EXCLUDED.replaced_by
;

GRANT SELECT
   ON TABLE currency
   TO public
;

RESET search_path
;

COMMIT
;
