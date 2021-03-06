



/*
  prototype for the prize_code_sum function

  using SELECT is about 3.5x slower than using a loop iterator
  see prize-code-sum-function-nt-iterator.sql

  prize_code_nt is the the type stored in the schema, and is based on the object prize_code_obj_typ

 SQL# desc prize_code_nt
 prize_code_nt TABLE OF PRIZE_CODE_OBJ_TYP
 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 CODE_NUM                                           NUMBER(2)

 probably should have made CODE_NUM as NOT NULL

*/


set serveroutput on format wrapped size unlimited


create or replace function prize_code_sum ( codes_in prize_code_nt )
return integer deterministic
is
	i_sum pls_integer := 0;

begin
	for pzrec in (
		select code_num
		from table(codes_in)
	)
	loop
		i_sum := i_sum + pzrec.code_num;
	end loop;
	return i_sum;
end;
/

show error function prize_code_sum


