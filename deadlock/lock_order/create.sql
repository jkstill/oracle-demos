

drop table table_1;
drop table table_2;

create table table_1 (col_1 number not null primary key, col_2 varchar2(5));
insert into table_1 values (1,'ABC');
commit;

create table table_2 (col_1 number not null primary key, col_2 varchar2(5));
insert into table_2 values (1,'ABC');
commit;

