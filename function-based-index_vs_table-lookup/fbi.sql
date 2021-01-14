
drop index func_test_fbi_idx;

create index func_test_fbi_idx on func_test(comp_id,pay_id, is_prime(rval))
/


