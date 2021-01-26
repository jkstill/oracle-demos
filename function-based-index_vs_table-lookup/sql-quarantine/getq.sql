
set serveroutput on format wrapped size unlimited

DECLARE
	quarantine_config_setting_value VARCHAR2(128);
BEGIN

	quarantine_config_setting_value := 
		DBMS_SQLQ.GET_PARAM_VALUE_QUARANTINE(
		QUARANTINE_NAME => 'SQL_QUARANTINE_fs1gz28ctgtj6a1e8c715',
		PARAMETER_NAME  => 'CPU_TIME');
	dbms_output.put_line('cpu time: ' || quarantine_config_setting_value );

	quarantine_config_setting_value := 
		DBMS_SQLQ.GET_PARAM_VALUE_QUARANTINE(
		QUARANTINE_NAME => 'SQL_QUARANTINE_fs1gz28ctgtj6a1e8c715',
		PARAMETER_NAME  => 'ELAPSED_TIME');
	dbms_output.put_line('elapsed time: ' || quarantine_config_setting_value );



END;
/
