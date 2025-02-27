SET
NOCOUNT ON
SELECT
    'INSERT INTO ' + CASE
        WHEN s.name LIKE '%.%' THEN QUOTENAME(s.name)
        WHEN s.name LIKE '% %' THEN QUOTENAME(s.name)
        ELSE s.name
    END + '.' + CASE
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
    '    ' + CASE
        WHEN c.name LIKE '%.%' THEN QUOTENAME(c.name)
        WHEN c.name LIKE '% %' THEN QUOTENAME(c.name)
        ELSE c.name
    END + CASE
        WHEN c.column_id = MAX(c.column_id) OVER () THEN ''
        ELSE ','
    END
FROM
    sys.schemas s
    INNER JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
    INNER JOIN sys.columns c ON o.object_id = c.object_id
WHERE
    o.object_id = OBJECT_ID('$(object)')
UNION ALL
SELECT
    ')'
UNION ALL
SELECT
    'VALUES ()'
