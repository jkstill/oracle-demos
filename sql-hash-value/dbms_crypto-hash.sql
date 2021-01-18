
set serveroutput on size unlimited format wrapped

declare
	md5hash raw(16);
	full_hash_value raw(16);
	c_sql clob;
begin
	c_sql := 'select dummy from dual';

	md5hash := 
		rawtohex(
			dbms_crypto.hash(
				src =>c_sql||chr(0), 
				typ => dbms_crypto.HASH_MD5 
			)
		);

	dbms_output.put_line('md5hash: ' || md5hash);

	full_hash_value := 
		utl_raw.reverse(utl_raw.substr(md5hash,1,4)) ||
		utl_raw.reverse(utl_raw.substr(md5hash,5,4)) ||
		utl_raw.reverse(utl_raw.substr(md5hash,9,4)) ||
		utl_raw.reverse(utl_raw.substr(md5hash,13)); 

	dbms_output.put_line('full_hash_value: ' || full_hash_value);

end;
/


