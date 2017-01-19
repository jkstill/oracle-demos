
set long 2000000
set pagesize 100

select dbms_stats.report_col_usage('JKSTILL', 'CARS') from   dual;
