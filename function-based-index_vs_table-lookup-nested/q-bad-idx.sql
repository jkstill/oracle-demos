

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

	   -- index(ft bad_idx) 
   /*+ gather_plan_statistics */

/*

using the comp_id, period_end_date, trans_type, status, and is_prime(rval), along
with phony index statistics create by stats.sql, cause
the bad_idx index to be favored

*/


select count(*)
from (
select /*+ gather_plan_statistics index(ft bad_idx) */
   rval, is_prime(rval) rprime
from func_test ft
where ft.comp_id = :comp_id
   and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')
   and ft.trans_type = 'B'
   and ft.status = 'ACTIVE'
   and is_prime(rval) = 'Y'
)
/

set tab off
col PLAN_TABLE_OUTPUT format a200

spool logs/q-bad-idx.log
@showplan_last
spool off



