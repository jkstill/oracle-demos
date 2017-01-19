

begin
	for i in 1..100000000
	loop
		dbms_application_info.set_module('','');
	end loop;
end;
/


