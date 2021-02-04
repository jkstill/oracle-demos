
@get-curr-ospid

prompt
prompt Testing speed of 'select into var'
prompt
prompt Press ENTER when ready
prompt

accept dummy
prompt Working...
prompt

set timing on

declare
	vDate date;
begin
	for i in 1..1e6
	loop
		select sysdate into vDate from dual;
	end loop;
end;
/


