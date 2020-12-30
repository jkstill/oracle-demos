
-- using Carlos Sierra's compute_sql_id

prompt
prompt should be 0k8522rmdzg4k
prompt

select compute_sql_id('select privilege# from sysauth$ where (grantee#=:1 or grantee#=1) and privilege#>0') from dual
/
