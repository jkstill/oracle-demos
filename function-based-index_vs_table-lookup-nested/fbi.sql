
drop index func_test_prz_fbi_idx;

create index func_test_prz_fbi_idx on func_test_prize(comp_id,pay_id, prize_code_sum(prize_codes))
/


