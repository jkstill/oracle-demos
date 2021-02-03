
begin
	dbms_resource_manager_privs.grant_switch_consumer_group(
		grantee_name => 'SCOTT',
		consumer_group => 'squash',
		grant_option => false
	);
end;
/ 
