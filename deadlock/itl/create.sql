

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



