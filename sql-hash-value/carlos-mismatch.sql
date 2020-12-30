
/*

As per "Querying V$Access Contents On Latch: Library Cache (Doc ID 757280.1)"
it may be necessary to append chr(0), and/or other magic cookies to the object being hashed

I have seen and used chr(0) in other SQL, and that is used to identify a 'cursor' as per this note.

hexdump: 
https://github.com/jkstill/hexadecimal/tree/master/hexdump


compute_sql_id: Carlos Sierra routine to calculate sql_id
https://carlos-sierra.net/2013/09/12/function-to-compute-sql_id-out-of-sql_text

*/

prompt

spool carlos-mismatch.log

declare
	v_orig_sql clob;
	v_sql_to_chk clob;
	v_orig_sql_id varchar2(13) := '9s5cdq3h4nfbj';
	v_new_sql_id varchar2(13);
	type v_sql_tab_typ is table of integer index by varchar2(13);
	v_sql_tab v_sql_tab_typ;
begin


	for sqlrec in (
		select sql_id, sql_fulltext
		from v$sqlarea
		order by sql_id
	)
	loop
		v_orig_sql_id := sqlrec.sql_id;
		v_orig_sql := sqlrec.sql_fulltext;

		--n_lob_len := dbms_lob.getlength(c_sql);
		--dbms_output.put_line('  calc_hash.sql len: ' || n_lob_len);
		-- oracle uses the first 32767 bytes of the string to calculate the hash
		v_sql_to_chk := dbms_lob.substr(v_orig_sql,32767,1);


		begin
			v_sql_tab(v_orig_sql_id) := v_sql_tab(v_orig_sql_id) + 1;
		exception
		when no_data_found then
			v_sql_tab(v_orig_sql_id) := 1;
		end;

		-- no need to compute again for the same SQL
		continue when v_sql_tab(v_orig_sql_id) > 1;

		--dbms_output.put_line('sql : |' || v_sql_to_chk || '|');
		--dbms_output.put_line('orig sql_id: ' || v_orig_sql_id );

		-- many SQL statements have 1 or more trailing spaces
		-- so I tried trim(v_sql_to_chk)
		-- that caused all computed SQL_ID to be incorrect
		v_new_sql_id := compute_sql_id(v_sql_to_chk );

		if v_new_sql_id != v_orig_sql_id then
			dbms_output.put_line(rpad('=',80,'='));
			dbms_output.put_line('Mismatch');
			dbms_output.put_line('orig sql_id: ' || v_orig_sql_id);
			dbms_output.put_line(' gen sql_id: ' || v_new_sql_id);
			dbms_output.put_line('sql: ' || dbms_lob.substr(v_sql_to_chk,4000,1));
			dbms_output.new_line;

			/*
			-- try again with a space appended 
			-- many failing sql have a space at the end
			-- this did not help

			-- left it here to remind me I already tried this
		 	v_new_sql_id := compute_sql_id(v_sql_to_chk || ' ');

			if v_new_sql_id = v_orig_sql_id then
				dbms_output.put_line('Match found with SPACE!');
				dbms_output.put_line('orig sql_id: ' || v_orig_sql_id );
				continue;
			end if;
			*/


			-- dump the SQL
			-- https://github.com/jkstill/hexadecimal/tree/master/hexdump

			for srec in (
				select address, data, text
				from TABLE(hexdump.hexdump(v_sql_to_chk))
			)
			loop
				dbms_output.put(srec.address || ' ');
				dbms_output.put(rpad(srec.data,48,' '));
				dbms_output.put_line(srec.text);
			end loop;

		end if;

	end loop;


end;
/
spool off

ed carlos-mismatch.log

