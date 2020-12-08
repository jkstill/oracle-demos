
/*

 Jared Still - 2020-12-06
 jkstill@gmail.com

*/

col full_hash_value format a80 
col sql_text format a80 
set linesize 200 trimspool on

col capture_sql new_value sql_text noprint

set term off feed off
select q'[select 'gen_sql_hash test' from dual]' capture_sql from dual;
set term on feed on

-- 4uqr7fxm12s3u - found in 10046 trace
select 'gen_sql_hash test' from dual;

select distinct sql_id, hash_value, sql_text from v$sql where sql_id = '4uqr7fxm12s3u'; 

select gen_sql_hash.gen_full_hash_value(sql_text_in => q'[&sql_text]') full_hash_value from dual;

select gen_sql_hash.gen_full_hash_value(sql_id_in => '4uqr7fxm12s3u') full_hash_value from dual;

select gen_sql_hash.gen_sql_id( sql_text_in =>  q'[&sql_text]') sql_id from dual;

select gen_sql_hash.gen_hash_value( sql_text_in =>  q'[&sql_text]') hash_value from dual;



