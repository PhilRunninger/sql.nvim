SET NOCOUNT ON

SELECT 'USE ' + QUOTENAME(DB_NAME())
UNION ALL
SELECT 'GO'
UNION ALL
SELECT
    'EXEC sp_help ''' +
    CASE  /* schema name */
        WHEN s.name LIKE '%.%' THEN QUOTENAME(s.name)
        WHEN s.name LIKE '% %' THEN QUOTENAME(s.name)
        ELSE s.name
    END + '.' +
    CASE  /* object name */
        WHEN o.name LIKE '%.%' THEN QUOTENAME(o.name)
        WHEN o.name LIKE '% %' THEN QUOTENAME(o.name)
        ELSE o.name
    END +
    ''''
FROM
    sys.schemas s
    INNER JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
WHERE
    o.object_id = OBJECT_ID('$(object)')
