with b1 as ( select radix.bitor( power(2,63), power(2,59)) b from dual),
b2 as ( select radix.bitor(b1.b,power(2,42)) b from b1),
b3 as ( select radix.bitor(b2.b,power(2,17)) b from b2),
b4 as ( select radix.bitor(b3.b, power(2,7)) b from b3)
select radix.to_bin(b4.b) from b4
/
