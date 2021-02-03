with b1 as ( select ( power(2,63) + power(2,59) ) -  bitand( power(2,63), power(2,59)) b from dual),
b2 as ( select ( b1.b + power(2,42) ) - bitand(b1.b,power(2,42)) b from b1),
b3 as ( select ( b2.b + power(2,17) ) - bitand(b2.b,power(2,17)) b from b2),
b4 as ( select ( b3.b + power(2,7) ) - bitand(b3.b, power(2,7)) b from b3)
select radix.to_bin(b4.b) from b4
/
