
-- showplan_last.sql
-- works with 9.2+

SET PAUSE OFF
SET VERIFY OFF
set trimspool on
set line 500 arraysize 1
clear break
clear compute


set linesize 250 trimspool on
set pagesize 200

select *
-- show estimated and elapsed timings
from table(dbms_xplan.display_cursor( null,null,'ALL ALLSTATS LAST'))
-- shows outline data - useful get query block names for hinting
--from table(dbms_xplan.display_cursor( null,null,'ADVANCED LAST'))
/


