

begin

	dbms_stats.delete_table_stats(ownname => user, tabname => 'FUNC_TEST', cascade_indexes => true);

	dbms_stats.gather_table_stats(ownname => user, tabname => 'FUNC_TEST');

	dbms_stats.gather_index_stats(user,'BAD_IDX');
	dbms_stats.gather_index_stats(user,'COMP_ID_IDX');
	dbms_stats.gather_index_stats(user,'FUNC_TEST_FBI_IDX');


end;
/

@@show-stats

