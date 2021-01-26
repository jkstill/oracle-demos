
begin
	dbms_resource_manager.create_simple_plan(
		simple_plan => 'restrictive_plan',
		consumer_group1 => 'normal', group1_percent => 99,
		consumer_group2 => 'squash', group2_percent => 1
	);
end;
/
