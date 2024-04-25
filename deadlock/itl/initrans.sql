
select table_name, tablespace_name, ini_trans from user_tables where table_name = 'ITL_WAIT'
/

select index_name, tablespace_name, ini_trans from user_indexes where index_name = 'ITL_WAIT_U_IDX'
/
