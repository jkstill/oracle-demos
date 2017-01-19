
drop table ctest purge;

create table ctest as select * from dba_objects;

insert into ctest select * from ctest;

/
/
/
/

commit;


