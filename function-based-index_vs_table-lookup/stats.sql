




begin

	--dbms_stats.delete_table_stats(ownname => user, tabname => 'FUNC_TEST', cascade_indexes => true);

	dbms_stats.gather_table_stats(ownname => user, tabname => 'FUNC_TEST');

	dbms_stats.delete_index_stats(user,'BAD_IDX');
	dbms_stats.delete_index_stats(user,'COMP_ID_IDX');


	dbms_stats.set_index_stats(
		ownname => user, 
		indname => 'BAD_IDX', 
		no_invalidate => FALSE,
		indlevel => 2,
		numlblks => 8,
		numrows => 100,
		numdist => 100,
		clstfct => 8
	);

	dbms_stats.set_index_stats(
		ownname => user, 
		indname => 'COMP_ID_IDX', 
		no_invalidate => FALSE,
		indlevel => 5,
		numlblks => 32000,
		numrows => 10e6,
		numdist => 1e6,
		clstfct => 1e6
	);


end;
/

col object_name format a30

select table_name object_name, last_analyzed from user_tables where table_name = 'FUNC_TEST'
union all
select index_name object_name, last_analyzed from user_indexes where table_name = 'FUNC_TEST'
/

