set NOCOUNT on

select
    'DECLARE ' + p.name + '_Out ' +
    lower(tp.name) +
    case when tp.name in ('varchar', 'char', 'varbinary', 'binary', 'text') then '(' + case when p.max_length = -1 then 'MAX' else CAST(p.max_length as VARCHAR(5)) end + ')'
         when tp.name in ('nvarchar', 'nchar', 'ntext')                     then '(' + case when p.max_length = -1 then 'MAX' else CAST(p.max_length / 2 as VARCHAR(5)) end + ')'
         when tp.name in ('datetime2', 'time2', 'datetimeoffset')           then '(' + CAST(p.scale as VARCHAR(5)) + ')'
         when tp.name in ('decimal', 'numeric')                             then '(' + CAST(p.[precision] as VARCHAR(5)) + ',' + CAST(p.scale as VARCHAR(5)) + ')'
         else ''
    end + ';' as parameterInfo
from sys.schemas s
inner join sys.objects o ON o.[schema_id] = s.[schema_id]
inner join sys.parameters p on o.object_id = p.object_id and p.parameter_id <> 0
inner join sys.types tp ON p.user_type_id = tp.user_type_id
where p.is_output = 1
and o.object_id = OBJECT_ID('$(object)')
--
union all
select 'EXECUTE $(object)'
--
union all
--
select
    case p.parameter_id when 1 then '    ' else '   ,' end +
    p.name + ' = ' +
    case p.is_output when 1 then p.name + '_Out OUTPUT' else '' end
from sys.schemas s
inner join sys.objects o ON o.[schema_id] = s.[schema_id]
inner join sys.parameters p on o.object_id = p.object_id and p.parameter_id <> 0
where o.object_id = OBJECT_ID('$(object)')
--
union all
--
select
    'PRINT ' + p.name + '_Out;'
from sys.schemas s
inner join sys.objects o ON o.[schema_id] = s.[schema_id]
inner join sys.parameters p on o.object_id = p.object_id and p.parameter_id <> 0
inner join sys.types tp ON p.user_type_id = tp.user_type_id
where p.is_output = 1
and o.object_id = OBJECT_ID('$(object)')
