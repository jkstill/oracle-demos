
drop table func_test purge;

create table func_test (
	comp_id number,
	comp_name varchar2(20),
	pay_id number,
	credit_id number,
	period_end_date date,
	trans_type varchar2(1),
	status varchar2(10),
	rval number,
	c1 varchar2(20),
	c2 varchar2(20),
	c3 varchar2(20)
)
/


-- fairly selective index
create index  comp_id_idx on func_test(comp_id, pay_id);


-- not so selective index
-- coupled with fake index stats (@stats.sql) this index gets favored in q1.sql
create index  bad_idx on func_test(rval, period_end_date);

-- oracle refuses to use this index when hinted
-- create index  bad_idx on func_test(rval, trans_type);




