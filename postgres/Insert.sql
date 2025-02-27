SELECT
    outputText
FROM
    (
        SELECT
            1 a,
            1 b,
            'INSERT INTO ' || QUOTE_IDENT(table_schema) || '.' || QUOTE_IDENT(table_name) || ' (' outputText
        FROM
            information_schema.tables
        WHERE
            table_schema || '.' || table_name = REPLACE(:'object', '"', '')
        UNION ALL
        SELECT
            2,
            ordinal_position,
            '    ' || QUOTE_IDENT(column_name) || CASE
                WHEN ordinal_position = MAX(ordinal_position) OVER () THEN ''
                ELSE ','
            END outputText
        FROM
            information_schema.columns
        WHERE
            table_schema || '.' || table_name = REPLACE(:'object', '"', '')
        UNION ALL
        SELECT
            3,
            1,
            ')'
        UNION ALL
        SELECT
            4,
            1,
            'VALUES ()'
    ) _
ORDER BY
    a,
    b
