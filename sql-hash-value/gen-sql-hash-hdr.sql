
create or replace package gen_sql_hash
is
	function gen_full_hash_value ( sql_id_in varchar2 ) return varchar2;
	function gen_full_hash_value ( sql_text_in clob ) return varchar2;
end;
/

show errors package gen_sql_hash

