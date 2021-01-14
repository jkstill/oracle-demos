
col index_name format a20
col column_name format a15
col column_position format 999 head 'COLPOS'

break on index_name skip 1 

select index_name, column_name, column_position
from user_ind_columns
where table_name = 'FUNC_TEST'
order by 1,2,3
/
