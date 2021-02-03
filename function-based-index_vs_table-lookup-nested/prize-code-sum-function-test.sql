
/*

 This is naive bit of SQL, as the prize_code_sum() function is executed more than necessary
 fine for this bit of testing

*/


with data as (
select distinct
	f.comp_id
	, f.pay_id
	, f.credit_id
	-- the column in the PRIZE_CODE_OBJ_TYP
	, sum(fp.code_num) over ( partition by f.comp_id, f.pay_id, f.credit_id ) code_sum
	, max(prize_code_sum(f.prize_codes)) over ( partition by f.comp_id, f.pay_id, f.credit_id ) code_sum_f
from func_test_prize f
	, table(f.prize_codes) fp
),
results as (
select
	d.comp_id
	, d.pay_id
	, d.credit_id
	, d.code_sum
	, d.code_sum_f
	, case d.code_sum_f - d.code_sum
		when 0 then 'OK'
		else 'Error Encountered!'
	end code_results
from data d
)
select * from results where code_results != 'OK'
/
