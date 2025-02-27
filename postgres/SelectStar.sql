SELECT
    'SELECT *'
UNION ALL
SELECT
    'FROM ' || QUOTE_IDENT(table_schema) || '.' || QUOTE_IDENT(table_name) || ' LIMIT 100'
FROM
    information_schema.tables
WHERE
    table_schema || '.' || table_name = REPLACE(:'object', '"', '')
