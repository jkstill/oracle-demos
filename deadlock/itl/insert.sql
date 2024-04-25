
truncate table itl_wait;

insert into itl_wait
select id, c1
from 
(
	select 
		level id
		-- 2679 is the largest value that will create 3 rows in the 8192 byte ASSM block
		-- 2352 is the largest value that will create 3 rows in the 8192 byte ASSM block in 21c ATP in oracle cloud, as well as 23c
		, rpad('X',2352,'X') c1
		-- all sessions will succeed when set to 100
		--, rpad('X',100,'X') c1
	from dual
	connect by level <= 9
	order by 1
)
/

commit;

