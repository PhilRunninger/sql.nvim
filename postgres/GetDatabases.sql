SELECT
    datname
FROM
    pg_database
WHERE
    datistemplate = FALSE;
