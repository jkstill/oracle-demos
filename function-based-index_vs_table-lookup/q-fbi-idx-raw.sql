
@@q-parms-01


select count(*)
from (
select /*+ gather_plan_statistics index(ft func_test_fbi_idx) */
   rval, is_prime(rval) rprime
from func_test ft
where ft.comp_id = :comp_id
   and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')
   and ft.trans_type = 'B'
   and ft.status = 'ACTIVE'
   and is_prime(rval) = 'Y'
)
/

