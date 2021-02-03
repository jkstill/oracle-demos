
-- 
-- This is Jared Still's prime code
-- from a PL/SQL prime number generator competition, long ago
--

set serveroutput on size 1000000

create table primes 
	prime_number integer not null,
	constraint pk_prime primary key (prime_number)
) organization index;

truncate table primes;


create or replace package primefactor 
as

	type nonPrimeRecordType is record
	(test_factor primes.prime_number%type);

	type nonPrimeTableType is table of nonPrimeRecordType
	index by binary_integer;

	nonPrimeTable nonPrimeTableType;
	emptyNonPrimeTAble nonPrimeTableType;

end;
/

set timing on

declare
	ftinit integer;
	i integer :=2;
	j integer :=0;
	l integer :=0;
	--v_prime_limit integer := 1000000;
	-- table func_test.rval has max of 999
	v_prime_limit integer := 1000;
	loop_counter integer := 1;
	v_array_el integer := 1;
	v_non_prime integer;

	-- 1 inserts
	-- 2 no inserts

	v_mode integer := 1;

	v_primes_found integer := 0;

	function is_prime ( prime_test_in integer, prime_limit_in integer ) return boolean
	is
		i integer;
		is_a_prime_number boolean;
		prime_number integer;
	begin
		
		-- obviously prime
		if prime_test_in = 1
			or prime_test_in = 2
			or prime_test_in = 3
			or prime_test_in = 5
			or prime_test_in = 7
		then
			return true;
		elsif mod(prime_test_in,2) = 0
		then
			return false;
		elsif mod(prime_test_in,3) = 0
		then
			return false;
		elsif mod(prime_test_in,5) = 0
		then
			return false;
		elsif mod(prime_test_in,7) = 0
		then
			return false;
		end if;
		

		-- determine other non-primes by multiplying this
		-- prime until the result exceeds the upper limit
		-- of integers being searched for primes
		i := 11;
		loop
			exit when ( i * prime_test_in ) > prime_limit_in;
			primefactor.nonPrimeTable( prime_test_in * i  ).test_factor := 1;
			i := i + 1;
		end loop;
		
		return true ;

	end;

Begin

	primefactor.nonPrimeTable := primefactor.emptyNonPrimeTable;

		loop 

			exit when loop_counter >= v_prime_limit;

			if not primefactor.nonPrimeTable.exists(loop_counter)
			then

				if is_prime(loop_counter,v_prime_limit)
				then
					if v_mode = 1
					then
						insert into primes values(loop_counter);
					elsif v_mode = 2
					then
						v_primes_found := v_primes_found + 1;
					end if;
				end if;

			end if;

			loop_counter := loop_counter + 2;

		end loop; 


	if v_mode = 1 
	then
		commit; 
	elsif v_mode = 2
	then
		dbms_output.put_line(v_primes_found || ' Primes Found');
	end if;

end;
/

set timing off

select count(*) from primes;

--@proof

