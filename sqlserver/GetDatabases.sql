SET NOCOUNT ON

SELECT name
FROM sys.databases
WHERE database_id > 4
AND name NOT LIKE 'ReportServer%'
ORDER BY name
