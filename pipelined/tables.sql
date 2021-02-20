
drop table pipeline_test purge;

create table pipeline_test
as
select owner, table_name
from all_tables
where rownum <= 200
/

