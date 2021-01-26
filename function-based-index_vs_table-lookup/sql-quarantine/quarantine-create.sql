DECLARE
	quarantine_config VARCHAR2(128);
BEGIN
	quarantine_config := DBMS_SQLQ.CREATE_QUARANTINE_BY_SQL_ID(
		SQL_ID => '00v5ashkdhw9n',
		PLAN_HASH_VALUE => '2716387093'
	);
	dbms_output.put_line('quarantine_config: ' || quarantine_config);
END;
/
