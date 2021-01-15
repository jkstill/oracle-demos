
exec dbms_stats.gather_table_stats(ownname => user, tabname => 'PRIMES')

@@show-stats

