
-- q2.sql
-- use the primes lookup table rather than is_prime()
--

set serveroutput off

col rprime format a6

var period_end_date varchar2(10)
var comp_id number
var pay_id number


begin
	:period_end_date := '2020-06-30';
	:comp_id := 42;
	:pay_id := 37;
end;
/


select count(*)
from (
select /*+ gather_plan_statistics */
   rval, 'Y' rprime
from func_test ft
join primes pf on pf.prime_number = ft.rval
where ft.comp_id = :comp_id
   and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')
   and ft.trans_type = 'B'
   and ft.status = 'ACTIVE'
   --and is_prime(rval) = 'Y'
)
/

--@showplan_last



