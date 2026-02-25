SET NOCOUNT ON

SELECT 'USE ' + QUOTENAME(DB_NAME())
UNION ALL
SELECT 'GO'
UNION ALL
SELECT
    'INSERT INTO ' + QUOTENAME(DB_NAME()) + '.' +  /* database */
    CASE  /* schema name */
        WHEN s.name LIKE '%.%' THEN QUOTENAME(s.name)
        WHEN s.name LIKE '% %' THEN QUOTENAME(s.name)
        ELSE s.name
    END + '.' +
    CASE  /* object name */
        WHEN o.name LIKE '%.%' THEN QUOTENAME(o.name)
        WHEN o.name LIKE '% %' THEN QUOTENAME(o.name)
        ELSE o.name
    END + ' ('
FROM
    sys.schemas s
    INNER JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
WHERE
    o.object_id = OBJECT_ID('$(object)')
UNION ALL
SELECT
    '    ' +
    CASE /* comma between columns */
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
SELECT ')'
UNION ALL
SELECT 'VALUES ('
UNION ALL
SELECT
    '    ' +
    CASE /* comma between columns */
        WHEN c.column_id > 1 THEN ','
        ELSE ''
    END +
    CASE
        WHEN tp.name IN ('tinyint', 'smallint', 'int', 'bigint', 'real', 'float', 'numeric', 'bit', 'decimal', 'smallmoney', 'money') THEN '  '
        ELSE ''''''
    END +
    '  /* ' + c.name + '*/'
FROM
    sys.schemas s
    INNER JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
    INNER JOIN sys.columns c ON o.object_id = c.object_id
    INNER JOIN sys.types tp ON c.user_type_id = tp.user_type_id
WHERE
    o.object_id = OBJECT_ID('$(object)')
UNION ALL
SELECT ')'
