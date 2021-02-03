
set serveroutput on format wrapped size unlimited

BEGIN
	dbms_sqlq.alter_quarantine(
		quarantine_name => 'SQL_QUARANTINE_fs1gz28ctgtj6a1e8c715',
		parameter_name  => 'ELAPSED_TIME',
		parameter_value => '3'
	);
END;
/

@@getq

