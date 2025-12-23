SET NOCOUNT ON

SELECT 'USE ' + DB_NAME()
UNION ALL
SELECT 'GO'
UNION ALL
SELECT
    'CREATE TABLE ' + DB_NAME() + '.' +  /* database */
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
    CASE /* column name */
        WHEN c.name LIKE '%.%' THEN QUOTENAME(c.name)
        WHEN c.name LIKE '% %' THEN QUOTENAME(c.name)
        ELSE c.name
    END + ' ' +
    LOWER(tp.name) +  /* data type */
    CASE
        WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text') THEN '(' + CASE
            WHEN c.max_length = -1 THEN 'MAX'
            ELSE CAST(c.max_length AS varchar(5))
        END + ')'
        WHEN tp.name IN ('nvarchar', 'nchar', 'ntext') THEN '(' + CASE
            WHEN c.max_length = -1 THEN 'MAX'
            ELSE CAST(c.max_length / 2 AS varchar(5))
        END + ')'
        WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset') THEN '(' + CAST(c.scale AS varchar(5)) + ')'
        WHEN tp.name IN ('decimal', 'numeric') THEN '(' + CAST(c.[precision] AS varchar(5)) + ',' + CAST(c.scale AS varchar(5)) + ')'
        ELSE ''
    END AS columnInfo
FROM
    sys.schemas s
    INNER JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
    INNER JOIN sys.columns c ON o.object_id = c.object_id
    INNER JOIN sys.types tp ON c.user_type_id = tp.user_type_id
WHERE
    o.object_id = OBJECT_ID('$(object)')
UNION ALL
SELECT ')'
