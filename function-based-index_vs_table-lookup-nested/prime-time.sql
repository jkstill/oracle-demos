
set timing on

prompt
prompt evaluate is_prime for 1..999 
prompt


declare
	v_is_prime varchar2(1);
begin
	for i in 1..999
	loop
		v_is_prime := is_prime(i);
	end loop;
end;
/

prompt
prompt evaluate is_prime for 1..999 ,  105 times
prompt

declare
	v_is_prime varchar2(1);
begin
	for j in 1..105
	loop
		for i in 1..999
		loop
			v_is_prime := is_prime(i);
		end loop;
	end loop;
end;
/

prompt
prompt evaluate is_prime for 1..999 ,  105 times, using SELECT
prompt

declare
	v_is_prime varchar2(1);
begin
	for j in 1..105
	loop
		for i in 1..999
		loop
			select is_prime(i) into v_is_prime from dual;
		end loop;
	end loop;
end;
/

