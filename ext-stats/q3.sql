

select /*+ gather_plan_statistics */ 
	color, tranny, seats, count(*)
from cars
where color = 'BEIGE'
	and tranny = 'AUTO'
	and seats = 'VINYL'
group by color, tranny, seats
/

