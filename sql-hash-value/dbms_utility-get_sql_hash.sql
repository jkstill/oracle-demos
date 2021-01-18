

set serveroutput on size unlimited format wrapped

declare
	hash_value number;
	v_sql varchar2(100);
	r_full_hash_value raw(16);
	corrected_full_hash_value raw(16);
	raw_pre10_hash number;
begin
	v_sql := 'select dummy from dual';
	hash_value := dbms_utility.get_sql_hash( 
		name => v_sql || chr(0)
		, hash => r_full_hash_value
		, pre10ihash => raw_pre10_hash
	);

	dbms_output.put_line('hash_value: ' || to_char(hash_value));

	dbms_output.put_line('full_hash_value: ' || r_full_hash_value);

	corrected_full_hash_value := 
		utl_raw.reverse(utl_raw.substr(r_full_hash_value,1,4)) ||
		utl_raw.reverse(utl_raw.substr(r_full_hash_value,5,4)) ||
		utl_raw.reverse(utl_raw.substr(r_full_hash_value,9,4)) ||
		utl_raw.reverse(utl_raw.substr(r_full_hash_value,13)); 

	dbms_output.put_line('corrected_full_hash_value: ' || corrected_full_hash_value);
end;
/


