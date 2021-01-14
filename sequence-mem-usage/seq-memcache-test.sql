

/*

This test was to see how much memory is used for sequence cache

Answer is in this doc:
Resolving Issues For Sequence Cache Management Causing Contention (Doc ID 1477695.1)

The amount used is always 4k (at least here)

All it does is set a max value in the instance.
The database is not revisited until the local value is maxed out.

*/

set serveroutput on format wrapped size unlimited

--drop sequence memcache_seq;

--create sequence memcache_seq nocache;

var seqname varchar2(30)

exec :seqname:='MEMCACHE_SEQ'

declare
	i_min_cache_size pls_integer := 10000;
	i_max_cache_size pls_integer := 500000;
	i_cache_size_increment pls_integer := 10000;
	c_sql clob;
	n_mem_used number;
	n_seq_val pls_integer;
begin
	delete from seq_cache_mem_test where sequence_name = :seqname;
	commit;

	c_sql := 'alter sequence ' || :seqname || ' cache ';

	for new_cache_size in i_min_cache_size .. i_max_cache_size
	loop
		continue when mod(new_cache_size,i_cache_size_increment) != 0;
		execute immediate c_sql || new_cache_size;

		--dbg.pl('cache size: ' || to_char(new_cache_size));
		--dbg.pl('sql: ' || c_sql);

		n_seq_val :=  MEMCACHE_SEQ.nextval;
		dbg.pl('new: ' || n_seq_val);

		select sharable_mem into n_mem_used from v$db_object_cache where name = :seqname;

		insert into seq_cache_mem_test ( sequence_name, cache_size, memory_used )
		values(:seqname,new_cache_size,n_mem_used);


	end loop;

	commit;

end;
/

select * from seq_cache_mem_test;




