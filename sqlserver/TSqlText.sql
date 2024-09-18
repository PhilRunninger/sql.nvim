set NOCOUNT on

SELECT text
FROM syscomments c
JOIN sys.objects o ON o.object_id = c.id
where o.object_id = OBJECT_ID('$(object)')
order by colid
