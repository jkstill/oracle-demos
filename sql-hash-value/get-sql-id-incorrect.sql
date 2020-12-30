
-- using Carlos Sierra's compute_sql_id

prompt
prompt should be 0jqxg6f2fzpr3
prompt

select compute_sql_id('SELECT DECODE(USER, ''XS$NULL'',  XS_SYS_CONTEXT(''XS$SESSION'',''USERNAME''), USER) FROM DUAL') from dual
/
