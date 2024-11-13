SELECT datname
from pg_database
where datistemplate = false;
