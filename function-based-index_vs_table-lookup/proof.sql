
set serveroutput on size 1000000

begin

	for prec in ( select prime_number from primes )
	loop
	
		for prime_test in 2 .. ( prec.prime_number -1 )
		loop
			if mod( prec.prime_number, prime_test) = 0
			then
				dbms_output.put_line( prec.prime_number || ' is divisible by ' || prime_test );
			end if;
		end loop;

	end loop;

end;
/


