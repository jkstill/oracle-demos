


-- format wrapped preserves leading whitespace
set serveroutput on size unlimited format wrapped

declare
	c_sql clob;
	md5hash varchar2(32);
	sepline_len integer;
	sepline varchar2(100);
	i_sqlnum integer;
	my_dummy number;
	n_lob_len number;

begin

	sepline_len := 60;
	sepline := rpad('=',sepline_len,'=');

	i_sqlnum := 0;

	for sqlrec in (
		with data as (
			select distinct sql_id, full_hash_value, sql_text
			from v$sql s
			join v$db_object_cache o on o.hash_value = s.hash_value
				--and length(s.sql_text) <= 80
				--and rownum <= 5000
			order by sql_id
		)
		select sql_id, full_hash_value, sql_text
		from data
		--where rownum <= 40
	)
	loop
		
		n_lob_len := dbms_lob.getlength(sqlrec.sql_text);
		dbms_output.put_line('  sql len: ' || n_lob_len);

		md5hash := gen_sql_full_hash_value(sqlrec.sql_id);
		i_sqlnum := i_sqlnum + 1;

		dbms_output.put_line('     sql#: ' || i_sqlnum);
		dbms_output.put_line('   sql_id: ' || sqlrec.sql_id);
		dbms_output.put_line('      sql: ' || sqlrec.sql_text);
		dbms_output.put_line('full_hash: ' || sqlrec.full_hash_value);
		dbms_output.put_line('calc hash: ' || md5hash);

		if sqlrec.full_hash_value != md5hash then
			dbms_output.put_line(' ==>> MISMATCH ==<< ');
			--raise_application_error(-20000,'HASH Mismatch');
		end if;

		dbms_output.put_line(sepline);

	end loop;
end;
/


