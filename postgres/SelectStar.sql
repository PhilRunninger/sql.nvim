SELECT 'SELECT *'
UNION ALL
SELECT 'FROM "' || table_schema || '"."' || table_name || '" LIMIT 100'
FROM information_schema.tables
WHERE '[' || table_schema || '].[' || table_name || ']' = :'object'
