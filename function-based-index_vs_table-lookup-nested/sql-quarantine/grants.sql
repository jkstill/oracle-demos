
grant select, insert, update, delete on func_test  to scott;
grant execute on is_prime to scott;

create or replace public synonym func_test for jkstill.func_test;
create or replace public synonym is_prime for jkstill.is_prime;


