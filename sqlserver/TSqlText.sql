set NOCOUNT on

;with cte as (
    SELECT -1 as colid, 'USE ' + DB_NAME() as text
    UNION ALL
    SELECT 0, 'GO'
    UNION ALL
    SELECT colid, text
    FROM syscomments c
    JOIN sys.objects o ON o.object_id = c.id
    where o.object_id = OBJECT_ID('$(object)')
)
SELECT text
FROM cte
order by colid
