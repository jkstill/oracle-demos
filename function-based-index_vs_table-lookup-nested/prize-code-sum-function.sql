



/*
  prototype for the prize_code_sum function

  input is a nested table prize_code_nt, with
  an unknown number of rows.

*/


set serveroutput on format wrapped size unlimited


create or replace function prize_code_sum ( codes_in prize_code_nt )
return integer
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


