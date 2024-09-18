set NOCOUNT on

select 'UPDATE [' + s.name + '].[' + o.name + ']'
FROM sys.schemas s
inner JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
where o.object_id = OBJECT_ID('$(object)')
UNION ALL
select 'SET'
UNION ALL
select case c.column_id when 1 then '     [' else '    ,[' end + c.name + '] = '
FROM sys.schemas s
inner JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
inner join sys.columns c on o.object_id = c.object_id
where o.object_id = OBJECT_ID('$(object)')
UNION ALL
select 'WHERE '
