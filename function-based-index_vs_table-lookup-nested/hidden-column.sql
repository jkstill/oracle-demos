select 
	column_id
	, column_name
	, nullable
	, hidden_column
from user_tab_cols
where table_name = 'FUNC_TEST'
order by column_id
/
