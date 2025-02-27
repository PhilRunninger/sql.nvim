SELECT
    outputText
FROM
    (
        SELECT
            1 a,
            1 b,
            'UPDATE ' || QUOTE_IDENT(table_schema) || '.' || QUOTE_IDENT(table_name) outputText
        FROM
            information_schema.tables
        WHERE
            table_schema || '.' || table_name = REPLACE(:'object', '"', '')
        UNION ALL
        SELECT
            2,
            1,
            'SET'
        UNION ALL
        SELECT
            3,
            ordinal_position,
            '    ' || QUOTE_IDENT(column_name) || ' = ' || CASE
                WHEN data_type LIKE '%char%' THEN ''''''
                WHEN data_type LIKE '%text%' THEN ''''''
                WHEN data_type LIKE '%date%' THEN ''''''
                WHEN data_type LIKE '%time%' THEN ''''''
                ELSE ''
            END || CASE
                WHEN ordinal_position = MAX(ordinal_position) OVER () THEN ''
                ELSE ','
            END
        FROM
            information_schema.columns
        WHERE
            table_schema || '.' || table_name = REPLACE(:'object', '"', '')
        UNION ALL
        SELECT
            4,
            1,
            'WHERE '
    ) _
ORDER BY
    a,
    b
