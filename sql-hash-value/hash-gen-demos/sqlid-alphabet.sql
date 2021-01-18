
-- sqlid-alphabet.sql
-- Jared Still 2021 jkstill@gmail.com
/*
 determine which characters are used to create SQL_ID values
 scan all sql_id values up to a limit of N, then decompose the 
 sql_id string into individual characters

 There should be 32. If there are fewer than 32, then increase N.

 the variable is 'i_sql_id_scan_limit' - 32 rows has worked in testing
*/

declare
	type sid_typ is table of pls_integer index by varchar2(1);
	sid_table sid_typ;
	v_sid_char varchar2(1);
	i_sql_id_scan_limit pls_integer := 32;
	v_sql_id_alphabet varchar2(32);
	i_sql_id_alpabet_len pls_integer;
begin
	for srec in (
		select distinct sql_id
		from v$sqlarea
		where rownum <= i_sql_id_scan_limit
	)
	loop
		for schar in (
			select substr(srec.sql_id,level,1) sql_id_char
			from dual
				connect by level < 14 -- sql_id has a length of 13
		)
		loop
			sid_table(schar.sql_id_char) := 1;
		end loop;
	end loop;

	v_sid_char := sid_table.first ;
	while v_sid_char is not null 
	loop
		v_sql_id_alphabet := v_sql_id_alphabet || v_sid_char;
		v_sid_char := sid_table.next(v_sid_char);
	end loop;

	i_sql_id_alpabet_len := length(v_sql_id_alphabet);

	dbms_output.new_line;
	dbms_output.put_line(v_sql_id_alphabet);

	if i_sql_id_alpabet_len != 32 then
		raise_application_error(-20000,'i_sql_id_alpabet_len too small at ' || to_char(i_sql_id_alpabet_len)
			|| ' - raise the value of i_sql_id_scan_limit');
	end if;

end;
/


