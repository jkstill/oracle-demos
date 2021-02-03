

drop type prize_code_nt;
drop type prize_code_obj_typ;

create type prize_code_obj_typ as object (
	code_num number(2,0)
)
/

create type prize_code_nt as table of prize_code_obj_typ
/

drop table func_test_prize purge;

create table func_test_prize (
	comp_id number,
	comp_name varchar2(20),
	pay_id number,
	credit_id number,
	period_end_date date,
	trans_type varchar2(1),
	status varchar2(10),
	prize_codes prize_code_nt,
	c1 varchar2(20),
	c2 varchar2(20),
	c3 varchar2(20)
)
nested table prize_codes store as nt_prize_codes
/


@@insert

-- this is no primary key
-- not good design, but this is often found in the wild

-- fairly selective index
create index  comp_id_prz_idx on func_test_prize(comp_id, pay_id);

-- not so selective index
-- coupled with fake index stats (@stats.sql) this index gets favored in q1.sql
create index bad_prz_idx on func_test_prize(c1, period_end_date);

-- nested table index
-- the index is created on the table type NT_PRIZE_CODES, as seen in the 'store as' clause in the nested table create statement
-- the code_num column is in th PRIZE_CODE_OBJ_TYP, which was used to create PRIZE_CODE_NT
create index nt_prize_codes_idx on nt_prize_codes(code_num);


