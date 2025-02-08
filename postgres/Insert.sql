SELECT 'INSERT INTO "' || table_schema || '"."' || table_name || '" ('
FROM information_schema.tables
WHERE '[' || table_schema || '].[' || table_name || ']' = :'object'
UNION ALL
SELECT CASE ordinal_position WHEN 1 THEN '    ' ELSE '   ,' END || column_name
FROM information_schema.columns
WHERE '[' || table_schema || '].[' || table_name || ']' = :'object'
UNION ALL
SELECT ')'
UNION ALL
SELECT 'VALUES ()'
