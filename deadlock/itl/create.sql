

drop table itl_wait purge;

create table itl_wait (
	id number,
	c1 varchar2(4000)
)
storage( initial 1 next 0 minextents 1 maxextents 1)
pctfree 0
initrans 1
maxtrans 1
/

create unique index itl_wait_u_idx on itl_wait(id)
storage( initial 1 next 0 minextents 1 maxextents 1)
pctfree 0
initrans 2
maxtrans 1
/


/*

drop table itl_wait_2 purge;

create table itl_wait_2 (
	id number,
	c1 varchar2(4000)
)
storage( initial 1 next 0 minextents 1 maxextents 1)
pctfree 0
initrans 1
maxtrans 1
/


create unique index itl_wait2_u_idx on itl_wait_2(id)
storage( initial 1 next 0 minextents 1 maxextents 1)
pctfree 0
initrans 2
maxtrans 1
/

*/

