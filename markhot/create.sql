
-- do not need any data, just for the table to exist

drop table hot_obj_test purge;

create table hot_obj_test (
	c0 number,
	c1 number,
	c2 number,
	c3 number,
	c4 number,
	c5 number,
	c6 number,
	c7 number,
	c8 number,
	c9 number
)
segment creation immediate
/
