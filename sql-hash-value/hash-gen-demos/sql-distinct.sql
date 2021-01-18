select sql_fulltext
from v$sql
where (sql_id, child_number) in  ( select sql_id, min(child_number) from v$sql group by sql_id)
/
