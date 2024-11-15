set nocount on

;with
objects as
(
    select charindex(type,'U V P FN FS IF TF') as sortOrder1, type, o.object_id,
        '[' + s.name + '].[' + o.name + ']' +
        isnull('  {' +
            lower(tp.name) +
            CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text') THEN '(' + CASE WHEN p.max_length = -1 THEN 'MAX' ELSE CAST(p.max_length AS VARCHAR(5)) END + ')'
                 WHEN tp.name IN ('nvarchar', 'nchar', 'ntext')                     THEN '(' + CASE WHEN p.max_length = -1 THEN 'MAX' ELSE CAST(p.max_length / 2 AS VARCHAR(5)) END + ')'
                 WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset')           THEN '(' + CAST(p.scale AS VARCHAR(5)) + ')'
                 WHEN tp.name IN ('decimal', 'numeric')                             THEN '(' + CAST(p.[precision] AS VARCHAR(5)) + ',' + CAST(p.scale AS VARCHAR(5)) + ')'
                 ELSE ''
            END + '}',
            '') as objectName
    FROM sys.schemas s
    JOIN sys.objects o ON o.[schema_id] = s.[schema_id]
    left outer join sys.parameters p on o.object_id = p.object_id and p.parameter_id = 0
    left outer join sys.types tp ON p.user_type_id = tp.user_type_id
    where is_ms_shipped = 0
    and type in ('U','V','P','FN','FS','IF','TF')
)
-- select * from objects
--
,categories as
(
    select min(sortOrder1) sortOrder1,
        case type
        when 'U' then 'Tables'
        when 'V' then 'Views'
        when 'P' then 'Stored Procedures'
        when 'FN' then 'Scalar Functions'
        when 'FS' then 'Scalar Functions'
        when 'IF' then 'Table-valued Functions'
        when 'TF' then 'Table-valued Functions'
        else 'Unknown'
        end as objectCategory
    from objects
    group by
        case type
        when 'U' then 'Tables'
        when 'V' then 'Views'
        when 'P' then 'Stored Procedures'
        when 'FN' then 'Scalar Functions'
        when 'FS' then 'Scalar Functions'
        when 'IF' then 'Table-valued Functions'
        when 'TF' then 'Table-valued Functions'
        else 'Unknown'
        end
)
-- select * from categories
--
,columns as
(
    select
        o.sortOrder1, o.objectName,
        c.column_id,
        c.name + '  {' +
        case when ic.column_id is null then '' else 'PK ' end +
        case when fkc.parent_object_id is null then '' else 'FK ' end +
        lower(tp.name) +
        CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text') THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(5)) END + ')'
             WHEN tp.name IN ('nvarchar', 'nchar', 'ntext')                     THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length / 2 AS VARCHAR(5)) END + ')'
             WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset')           THEN '(' + CAST(c.scale AS VARCHAR(5)) + ')'
             WHEN tp.name IN ('decimal', 'numeric')                             THEN '(' + CAST(c.[precision] AS VARCHAR(5)) + ',' + CAST(c.scale AS VARCHAR(5)) + ')'
             ELSE ''
        END +
        CASE WHEN c.is_nullable = 1 THEN '}' ELSE ' not null}' END as columnInfo
    from objects o
    inner join sys.columns c on o.object_id = c.object_id
    inner join sys.types tp ON c.user_type_id = tp.user_type_id
    left outer join sys.indexes i on c.object_id = i.object_id and i.is_primary_key = 1
    left outer join sys.index_columns ic on i.object_id = ic.object_id and i.index_id = ic.index_id and ic.column_id = c.column_id
    left outer join sys.foreign_key_columns fkc on c.object_id = fkc.parent_object_id and c.column_id = fkc.parent_column_id
)
-- select * from columns
--
,parameters as
(
    select
        o.sortOrder1, o.objectName,
        p.parameter_id,
        p.name + '  {' +
        lower(tp.name) +
        CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text') THEN '(' + CASE WHEN p.max_length = -1 THEN 'MAX' ELSE CAST(p.max_length AS VARCHAR(5)) END + ')'
             WHEN tp.name IN ('nvarchar', 'nchar', 'ntext')                     THEN '(' + CASE WHEN p.max_length = -1 THEN 'MAX' ELSE CAST(p.max_length / 2 AS VARCHAR(5)) END + ')'
             WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset')           THEN '(' + CAST(p.scale AS VARCHAR(5)) + ')'
             WHEN tp.name IN ('decimal', 'numeric')                             THEN '(' + CAST(p.[precision] AS VARCHAR(5)) + ',' + CAST(p.scale AS VARCHAR(5)) + ')'
             ELSE ''
        END + '}' as parameterInfo
    from objects o
    inner join sys.parameters p on o.object_id = p.object_id and p.parameter_id <> 0
    inner join sys.types tp ON p.user_type_id = tp.user_type_id
)
-- select * from parameters
--
,combined as
(
    select sortOrder1, '' objectName, 0 sortOrder2,           -1 sortOrder3,         objectCategory outputText
    from categories
    UNION
    select sortOrder1,    objectName, 0 sortOrder2,            0 sortOrder3,      '  ' + objectName outputText
    from objects
    UNION
    select sortOrder1,    objectName, 0 sortOrder2, parameter_id sortOrder3, '    ' + parameterInfo outputText
    from parameters
    UNION
    select sortOrder1,    objectName, 1 sortOrder2,    column_id sortOrder3,    '    ' + columnInfo outputText
    from columns
)
-- select * from combined
--
select outputText
from combined
order by sortOrder1, objectName, sortOrder2, sortOrder3
