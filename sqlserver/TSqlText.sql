set NOCOUNT on

;WITH sourceCode AS (
    SELECT ColID, Text
    FROM syscomments c
    JOIN sys.objects o ON o.object_id = c.id
    WHERE o.object_id = OBJECT_ID('$(object)')
)
,joinMarkers AS (
    SELECT ColID + 0.5 AS ColID, 'J3o.i1n4N1e5x9t2L6i5n3e5T8o9P7r9e3v2i3o8u4s6' AS Text, MAX(ColID) OVER() AS MaxColId
    FROM sourceCode
    WHERE ColID > 0
)
,combined AS (
    SELECT -1 as colid, 'USE ' + QUOTENAME(DB_NAME()) as text
    UNION ALL
    SELECT 0, 'GO'
    UNION ALL
    SELECT ColID, Text
    FROM sourceCode
    UNION ALL
    SELECT ColID, Text
    FROM joinMarkers
    WHERE ColId < MaxColId
)
SELECT Text
FROM combined
ORDER BY ColID
