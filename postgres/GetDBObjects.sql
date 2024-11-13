select outputText
from
(   select
        1 sortOrder1,
        0 sortOrder2,
        'Tables' outputText
    union all
    select
        1 sortOrder1,
        row_number() over (order by schemaname, tablename) sortOrder2,
        '  ['||schemaname||'].['||tablename||']' outputText
    from pg_tables
    where tableowner not in ('postgres')
    union all
    select
        2 sortOrder1,
        0 sortOrder2,
        'Views' outputText
    union all
    select
        2 sortOrder1,
        row_number() over (order by schemaname, viewname) sortOrder2,
        '  ['||schemaname||'].['||viewname||']'
    from pg_views
    where viewowner not in ('postgres')
) x
order by sortOrder1, sortOrder2
