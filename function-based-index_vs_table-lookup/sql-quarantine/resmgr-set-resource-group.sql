
begin
	dbms_resource_manager.set_initial_consumer_group(
		user => 'SCOTT',
		consumer_group => 'squash'
	); 
end;
/

