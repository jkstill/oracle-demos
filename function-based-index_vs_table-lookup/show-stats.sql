

col object_name format a30

select
	table_name object_name
	, 'TABLE' object_type
	, to_char(last_analyzed,'yyyy-mm-dd hh24:mi:ss') last_analyzed
	, blocks
	, num_rows
from user_tables
where table_name = 'FUNC_TEST'
union all
select
	index_name object_name
	, 'INDEX' object_type
	, to_char(last_analyzed,'yyyy-mm-dd hh24:mi:ss') last_analyzed
	, leaf_blocks blocks
	, num_rows
from user_indexes
where table_name in ('FUNC_TEST','PRIMES')
order by object_type desc, object_name
/

