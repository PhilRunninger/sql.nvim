set NOCOUNT on

select 'SELECT TOP 100 *'
UNION ALL
select 'FROM [' + s.name + '].[' + o.name + ']'
FROM sys.schemas s
inner JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
where o.object_id = OBJECT_ID('$(object)')

