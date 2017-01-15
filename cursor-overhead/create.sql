
-- create.sql

-- (C)ursor (T)est
drop table ct purge; 


create table ct 
tablespace cursor_test
pctfree 5
as
select
	level id
	, lpad('x',32,'x') c1
from dual
connect by level <= 1e6
/

create index ct_pk_idx on ct(id);

alter table ct add constraint ct_pk primary key(id);

exec dbms_stats.gather_table_stats(null,'CT')

