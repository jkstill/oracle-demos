
insert into itl_wait
select id, c1
from 
(
	select 
		level id
		-- 2679 is the largest value that will crete 3 rows in the 8192 byte ASSM block
		, rpad('X',2679,'X') c1
		-- all sessions will succeed when set to 100
		--, rpad('X',100,'X') c1
	from dual
	connect by level <= 10
	order by 1
)
/

commit;

