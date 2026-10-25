SET NOCOUNT ON

SELECT 'USE ' + QUOTENAME(DB_NAME())
UNION ALL
SELECT 'GO'
UNION ALL
SELECT 'SELECT TOP 100'
UNION ALL
SELECT
    '    ' +
    CASE  /* comma between columns */
        WHEN c.column_id > 1 THEN ','
        ELSE ''
    END +
    CASE  /* column name */
        WHEN c.name LIKE '%.%' THEN QUOTENAME(c.name)
        WHEN c.name LIKE '% %' THEN QUOTENAME(c.name)
        ELSE c.name
    END
FROM
    sys.schemas s
    INNER JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
    INNER JOIN sys.columns c ON o.object_id = c.object_id
WHERE
    o.object_id = OBJECT_ID('$(object)')
UNION ALL
SELECT
    'FROM ' + QUOTENAME(DB_NAME()) + '.' +  /* database */
    CASE /* schema name */
        WHEN s.name LIKE '%.%' THEN QUOTENAME(s.name)
        WHEN s.name LIKE '% %' THEN QUOTENAME(s.name)
        ELSE s.name
    END + '.' + /* object name */
    CASE
        WHEN o.name LIKE '%.%' THEN QUOTENAME(o.name)
        WHEN o.name LIKE '% %' THEN QUOTENAME(o.name)
        ELSE o.name
    END
FROM
    sys.schemas s
    INNER JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
WHERE
    o.object_id = OBJECT_ID('$(object)')
