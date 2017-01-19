


select /*+ gather_plan_statistics */ 
	color, tranny, seats, count(*)
from cars
where color = 'RED'
	and tranny = 'STICK'
	and seats = 'RECARO'
group by color, tranny, seats
/

