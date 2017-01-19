

select /*+ gather_plan_statistics */ 
	color, tranny, seats, count(*)
from cars
group by color, tranny, seats
/

