select outputText
from
(   select
        1 a,
        '' b,
        -1 c,
        'Tables' outputText
        ,'' owner
    union all
    select
        1 a,
        schemaname||tablename b,
        0 c,
        '  ['||schemaname||'].['||tablename||']' outputText
        ,tableowner
    from pg_tables
    where tableowner not in ('postgres')
    union all
    select
        2 a,
        '' b,
        -1 c,
        'Views' outputText
        ,'' owner
    union all
    select
        2 a,
        schemaname||viewname b,
        0 c,
        '  ['||schemaname||'].['||viewname||']' outputText
        ,viewowner
    from pg_views
    where viewowner not in ('postgres')
) x
order by a, b, c
