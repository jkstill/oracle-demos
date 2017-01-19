
select 'My Session : ' || s.sid, s.serial#, p.pid, p.spid
from v$session s,  v$process p
where s.paddr=p.addr
and s.sid = (select distinct sid from v$mystat);

set echo on
-- my first set of row/rows that are locked
--  here it is an INSERT -- this will cause another session to wait on the Primary Key !
insert into table_1 values (2,'S1');

pause Press ENTER to proceed .....

-- my second set of row/rows that are locked
insert into table_2  values (2,'S1');

commit;

set echo off
