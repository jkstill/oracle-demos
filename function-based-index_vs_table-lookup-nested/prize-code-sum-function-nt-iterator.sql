


set serveroutput on format wrapped size unlimited

/*

 prize_code_nt is the the type stored in the schema, and is based on the object prize_code_obj_typ

 This version of the function is 3.5x faster than the version using  `select code_num from table(codes_in)`
 see prize-code-sum-function.sql

 SQL# desc prize_code_nt
 prize_code_nt TABLE OF PRIZE_CODE_OBJ_TYP
 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 CODE_NUM                                           NUMBER(2)

 probably should have made CODE_NUM as NOT NULL

*/

create or replace function prize_code_sum ( codes_in prize_code_nt )
return integer deterministic
is
	i_sum pls_integer := 0;
	v_str varchar2(200);
begin
	for pz_index in codes_in.first .. codes_in.last
	loop
		i_sum := i_sum + codes_in(pz_index).code_num;
	end loop;
	return i_sum;
end;
/

show error function prize_code_sum


