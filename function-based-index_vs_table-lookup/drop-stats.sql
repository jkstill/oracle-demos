
exec dbms_stats.delete_table_stats(ownname => user, tabname => 'FUNC_TEST', cascade_indexes => true)


