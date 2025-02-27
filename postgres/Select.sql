SELECT
    outputText
FROM
    (
        SELECT
            1 a,
            1 b,
            'SELECT' outputText
        UNION ALL
        SELECT
            2,
            ordinal_position,
            '    ' || QUOTE_IDENT(column_name) || CASE
                WHEN ordinal_position = MAX(ordinal_position) OVER () THEN ''
                ELSE ','
            END
        FROM
            information_schema.columns
        WHERE
            table_schema || '.' || table_name = REPLACE(:'object', '"', '')
        UNION ALL
        SELECT
            3,
            1,
            'FROM ' || QUOTE_IDENT(table_schema) || '.' || QUOTE_IDENT(table_name) || ' LIMIT 100'
        FROM
            information_schema.tables
        WHERE
            table_schema || '.' || table_name = REPLACE(:'object', '"', '')
    ) _
ORDER BY
    a,
    b
