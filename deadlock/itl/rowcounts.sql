with data as (
select dbms_rowid.ROWID_BLOCK_NUMBER(rowid) blocknum  
	, i.id
	, i.c1
from itl_wait i
)
select distinct blocknum
	, count(*) over (partition by blocknum) rowcount
	, min(id) over (partition by blocknum) min_id
	, max(id) over (partition by blocknum) max_id
from data
order by 1,2
/

