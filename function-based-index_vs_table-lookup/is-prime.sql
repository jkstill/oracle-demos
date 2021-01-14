create or replace function is_prime ( prime_test_in integer ) return varchar2
	is
		i integer;
		is_a_prime_number boolean;
		prime_number integer;
	begin
		
		-- obviously prime
		if prime_test_in = 2
			or prime_test_in = 3
			or prime_test_in = 5
			or prime_test_in = 7
		then
			return 'Y';
		elsif prime_test_in = 1
		then
			return 'N';
		elsif mod(prime_test_in,2) = 0
		then
			return 'N';
		elsif mod(prime_test_in,3) = 0
		then
			return 'N';
		elsif mod(prime_test_in,5) = 0
		then
			return 'N';
		elsif mod(prime_test_in,7) = 0
		then
			return 'N';
		end if;
		
		--dbms_output.put_line('Passed basic mod tests ' );

		-- brute force prime detection
		i := 11;
		loop
			i := i + 2;

			if i > prime_test_in / 2 then
				exit;
			end if;

			if mod(prime_test_in,i) = 0 then
				--dbms_output.put_line('exiting because mod(' || prime_test_in || ' , ' || i || ') = 0');
				return 'N';
			end if;
		end loop;
		
		--dbms_output.put_line('exiting because prime');
		return 'Y' ;

	end;
/

show error function is_prime

