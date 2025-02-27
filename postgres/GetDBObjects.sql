SELECT
    outputText
FROM
    (
        SELECT
            1 a,
            '' b,
            -1 c,
            'Tables' outputText,
            '' owner
        UNION ALL
        SELECT
            1,
            schemaname || tablename,
            0,
            '  ' || QUOTE_IDENT(schemaname) || '.' || QUOTE_IDENT(tablename),
            tableowner
        FROM
            pg_tables
        WHERE
            tableowner NOT IN ('postgres')
        UNION ALL
        SELECT
            2,
            '',
            -1,
            'Views',
            ''
        UNION ALL
        SELECT
            2,
            schemaname || viewname,
            0,
            '  ' || QUOTE_IDENT(schemaname) || '.' || QUOTE_IDENT(viewname),
            viewowner
        FROM
            pg_views
        WHERE
            viewowner NOT IN ('postgres')
    ) x
ORDER BY
    a,
    b,
    c
