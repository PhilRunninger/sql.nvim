set NOCOUNT on

select 'CREATE TABLE [' + s.name + '].[' + o.name + '] ('
FROM sys.schemas s
inner JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
where o.object_id = OBJECT_ID('$(object)')
UNION ALL
select
    case c.column_id when 1 then '    [' else '   ,[' end + c.name + '] ' +
    lower(tp.name) +
    CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text') THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(5)) END + ')'
         WHEN tp.name IN ('nvarchar', 'nchar', 'ntext')                     THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length / 2 AS VARCHAR(5)) END + ')'
         WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset')           THEN '(' + CAST(c.scale AS VARCHAR(5)) + ')'
         WHEN tp.name IN ('decimal', 'numeric')                             THEN '(' + CAST(c.[precision] AS VARCHAR(5)) + ',' + CAST(c.scale AS VARCHAR(5)) + ')'
         ELSE ''
    END +
    CASE WHEN c.is_nullable = 1 THEN '' ELSE ' not null' END as columnInfo
FROM sys.schemas s
inner JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
inner join sys.columns c on o.object_id = c.object_id
inner join sys.types tp ON c.user_type_id = tp.user_type_id
where o.object_id = OBJECT_ID('$(object)')
UNION ALL
select ')'
