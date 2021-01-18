

-- find-max-sql-length-to-calc-hash.sql
-- Jared Still 2021 jkstill@gmail.com
--
-- use a 38k padded string to test amount of 
-- a SQL statement that is used to determine the MD5 and full_hash_value

set serveroutput on format wrapped size unlimited

declare
	c_sql clob;
	d_sql clob;
	v_full_hash_value varchar2(32);
	v_prev_full_hash_value varchar2(32);
begin

	dbms_output.put_line('Creating a 38k CLOB to test max length of SQL that is hashed');

	for i in 1..9
	loop
		c_sql := c_sql || rpad('X',4000,'X');
	end loop;

	for i in 32760 .. 32766
	loop

		d_sql :=  dbms_lob.substr(c_sql,i,1);

		--v_full_hash_value := gen_sql_hash.gen_full_hash_value(sql_text_in => d_sql );

		-- this can be done with MD5 as well
		v_full_hash_value := dbms_crypto.hash(src => d_sql , typ => dbms_crypto.hash_md5);

		if v_prev_full_hash_value = v_full_hash_value then
			dbms_output.put_line(rpad('=',80,'='));
			dbms_output.put_line('SQL Hash stopped changing at i - 1: ' || to_char(i-1));
			dbms_output.put_line('i-hash: '|| to_char(i) || ':' || v_full_hash_value);
			exit;
		end if;

		v_prev_full_hash_value := v_full_hash_value;

	end loop;

end;
/
