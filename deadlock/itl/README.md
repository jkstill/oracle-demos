
<h3>ITL Wait Demo</h3>

This is a simple demo to show how a shortage of ITL space causes deadlocks.

ITL = Interested Transaction List

ITL is well documented in many available articles, so if you are unsure what ITL is, just google it.

<h3>Create a table</h3>

This table is designed to hold 3 rows per block, using as much space per block as possible.

The table is created in an ASSM tablespace with an 8k blocksize.


create.sql

<pre>

create table itl_wait (
	id number,
	c1 varchar2(4000)
)
storage( initial 1 next 0 minextents 1 maxextents 1)
pctfree 0
initrans 1
maxtrans 1
/

</pre>

Oracle will actually ignore the 'maxtrans 1' argument, and will set it to 2.
The maxtrans 1 is also ignored by Oracle due to ASSM block management.

<h3>Insert</h3>

Now insert some rows.

The tablespace being used is ASSM with an 8k block size.
When varchar2 size of 2679 bytes is use 3 rows will fit in the block, using all, or very nearly all of the space in the block.

insert.sql

<pre>

insert into itl_wait
select id, c1
from 
(
	select 
		level id
		-- 2679 is the largest value that will crete 3 rows in the 8192 byte ASSM block
		, rpad('X',2679,'X') c1
		-- all sessions will succeed when set to 100
		--, rpad('X',100,'X') c1
	from dual
	connect by level <= 10
	order by 1
)
/

commit;

</pre>


<h3>Row Count</h3>

Now let's look at the rows per block.
There should be 3 rows in the block with the minimum ID of 1

rowcount.sql

<pre>

  1  with data as (
  2  select dbms_rowid.ROWID_BLOCK_NUMBER(rowid) blocknum
  3     , i.id
  4     , i.c1
  5  from itl_wait i
  6  )
  7  select distinct blocknum
  8     , count(*) over (partition by blocknum) rowcount
  9     , min(id) over (partition by blocknum) min_id
 10     , max(id) over (partition by blocknum) max_id
 11  from data
 12* order by 1,2
16:53:36 ora12c102rac01.jks.com - jkstill@js122a1 SQL> /

  BLOCKNUM   ROWCOUNT     MIN_ID     MAX_ID
---------- ---------- ---------- ----------
     43883          3          7          9
     43885          1         10         10
     43886          3          1          3
     43887          3          4          6

4 rows selected.

</pre>

Causing an ITL wait will require 3 sessions, as the minimum INITRANS value is always 2.

Session 1:

@u1

<pre>

update itl_wait
set c1 =  c1
where id = 1
/

</pre>

Session 2:

@u2

<pre>

update itl_wait
set c1 =  c1
where id = 2
/

</pre>

Session 3:

@u3

<pre>

update itl_wait
set c1 =  c1
where id = 3
/

</pre>

Session 3 should hang.

If it does not hang, it may be necessary to adjust the size of the insert into the C1 column and rebuild the table.


<h3>Show the TX Mode 4 Wait</h3>

blocked.sql

<pre>

  1  select
  2     sid, event
  3     , p1
  4     , chr(to_number(substr(TRIM(to_char(p1,'XXXXXXXXXXXXXXXX')),1,2),'XXXXXXXX'))
  5     || chr(to_number(substr(TRIM(to_char(p1,'XXXXXXXXXXXXXXXX')),3,2),'XXXXXXXX')) type
  6     , to_number(substr(TRIM(to_char(p1,'XXXXXXXXXXXXXXXX')),5),'XXXXXXXX') enq_mode
  7  from v$session
  8* where blocking_session is not null
16:48:08 ora12c102rac01.jks.com - sys@js122a1 SQL> /

   SID EVENT                                    P1 TY   ENQ_MODE
------ ------------------------------ ------------ -- ----------
    44 enq: TX - allocate ITL entry     1415053316 TX          4

1 row selected.

</pre>




Goto to 
