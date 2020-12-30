

prompt

spool carlos-mismatch.log

declare
	v_sql_to_chk clob;
	v_orig_sql_id varchar2(13) := '9s5cdq3h4nfbj';
	v_new_sql_id varchar2(13);
	type v_sql_tab_typ is table of integer index by varchar2(13);
	v_sql_tab v_sql_tab_typ;
begin


	for sqlrec in (
		select sql_id, sql_fulltext
		from v$sqlarea
	)
	loop
		v_orig_sql_id := sqlrec.sql_id;
		v_sql_to_chk := sqlrec.sql_fulltext;

		begin
			v_sql_tab(v_orig_sql_id) := v_sql_tab(v_orig_sql_id) + 1;
		exception
		when no_data_found then
			v_sql_tab(v_orig_sql_id) := 1;
		end;

		continue when v_sql_tab(v_orig_sql_id) > 1;

		--dbms_output.put_line('sql : |' || v_sql_to_chk || '|');
		--dbms_output.put_line('orig sql_id: ' || v_orig_sql_id );

		--select compute_sql_id(v_sql_to_chk ) into v_new_sql_id from dual;
		 v_new_sql_id := compute_sql_id(v_sql_to_chk );

		if v_new_sql_id != v_orig_sql_id then
			dbms_output.put_line(rpad('=',80,'='));
			dbms_output.put_line('Mismatch');
			dbms_output.put_line('orig sql_id: ' || v_orig_sql_id);
			dbms_output.put_line(' gen sql_id: ' || v_new_sql_id);
			dbms_output.put_line('sql: ' || v_sql_to_chk);
			dbms_output.new_line;

			-- try again with a space appended 
			-- many failing sql have a space at the end
			-- this did not help

		 	v_new_sql_id := compute_sql_id(v_sql_to_chk || ' ');

			if v_new_sql_id = v_orig_sql_id then
				dbms_output.put_line('Match found with SPACE!');
				dbms_output.put_line('orig sql_id: ' || v_orig_sql_id || chr(0));
				continue;
			end if;


			-- dump the SQL

			for srec in (
				select address, data, text
				from TABLE(hexdump.hexdump(v_sql_to_chk))
			)
			loop
				dbms_output.put(srec.address || ' ');
				dbms_output.put(srec.data || ' ');
				dbms_output.put_line(srec.text);
			end loop;

		end if;

	end loop;


end;
/
spool off

ed carlos-mismatch.log

