
create or replace package gen_sql_hash
authid definer
is

/*

 Jared Still - 2020-12-06
 jkstill@gmail.com

*/

	function gen_full_hash_value ( sql_id_in varchar2 ) return varchar2;
	function gen_full_hash_value ( sql_text_in clob ) return varchar2;
	function sql_id_to_hash (sql_id_in varchar2) return number;
	function gen_sql_id ( sql_text_in clob ) return varchar2;
	function gen_hash_value ( sql_text_in clob ) return number;
	function little_endian ( hash_str varchar2 ) return varchar2;
	function md5_to_sqlid(md5 in raw) return varchar2;
	function md5_to_sqlhash(md5 in raw) return number;

end;
/

show errors package gen_sql_hash

