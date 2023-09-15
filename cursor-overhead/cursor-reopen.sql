
-- t1.sql 
-- open/close cursor for each row
--

--alter session set session_cached_cursors = 0;

select 'This is the cursor REOPEN test' from dual;

set serveroutput on size unlimited

declare

	h_sql_cursor pls_integer;

	v_sql varchar2(1000) := 'select c1 from ct where id = :n_id' ;

	v_c1 ct.c1%type;

	rows_processed pls_integer;
	rows_fetched pls_integer;
	
	ct_error exception;
	pragma exception_init(ct_error,-20000);

	i_cursor_count pls_integer := 0;

function get_cursor_count return pls_integer
is
	cursor_count pls_integer;
begin
	select count(*) into cursor_count from v$open_cursor where sid = sys_context('userenv','sid');
	return cursor_count;
end;

begin

	dbms_output.enable(null);

	dbms_output.put_line('cursor count before: ' || to_char(get_cursor_count));

	--h_sql_cursor := dbms_sql.open_cursor;
	--dbms_sql.parse(h_sql_cursor, v_sql, dbms_sql.native);

	-- we know there are values of 1..1e6 for ID
	for i in 1..100000
	loop
		if not dbms_sql.is_open(h_sql_cursor) then
			--dbms_output.put_line('creating cursor');
			h_sql_cursor := dbms_sql.open_cursor;
			dbms_sql.parse(h_sql_cursor, v_sql, dbms_sql.native);
			dbms_sql.define_column(h_sql_cursor, 1, v_c1, 30);
		end if;

		dbms_sql.bind_variable(h_sql_cursor,':n_id',mod(i,100)+1);
		rows_processed := dbms_sql.execute(h_sql_cursor);
		rows_fetched := dbms_sql.fetch_rows(h_sql_cursor);

		if rows_fetched < 1 then
			dbms_output.put_line('looks like a bug - kill it Jim');
			raise ct_error;
		else
			dbms_sql.column_value(h_sql_cursor,1,v_c1);
		end if;

		--dbms_output.put_line(v_c1);

		if dbms_sql.is_open(h_sql_cursor) then
			dbms_sql.close_cursor(h_sql_cursor) ;
		end if;

	end loop;


	dbms_output.put_line('cursor count after: ' || to_char(get_cursor_count));

end;
/

