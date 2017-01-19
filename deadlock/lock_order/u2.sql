
select 'My Session : ' || s.sid, s.serial#, p.pid, p.spid
from v$session s,  v$process p
where s.paddr=p.addr
and s.sid = (select distinct sid from v$mystat);

set echo on
-- my first set of row/rows that are locked
--  here it is an INSERT -- this will cause another session to wait on the Primary Key !
select col_1, col_2 from table_1 where col_1 = 2 for update;

pause Press ENTER to proceed .....

-- my second set of row/rows that are locked
select col_1, col_2 from table_1 where col_1 = 1 for update;

commit;

set echo off

