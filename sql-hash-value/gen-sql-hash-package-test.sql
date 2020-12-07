
/*

 Jared Still - 2020-12-06
 jkstill@gmail.com

*/

col full_hash_value format a80 
col sql_text format a80 
set linesize 200 trimspool on

-- 4uqr7fxm12s3u - found in 10046 trace
select 'gen_sql_hash test' from dual;

select sql_text from v$sql where sql_id = '4uqr7fxm12s3u'; 

select gen_sql_hash.gen_full_hash_value(sql_text_in => 'select ''gen_sql_hash test'' from dual') full_hash_value from dual;

select gen_sql_hash.gen_full_hash_value(sql_id_in => '4uqr7fxm12s3u') full_hash_value from dual;



