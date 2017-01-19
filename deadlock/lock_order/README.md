
<h3>Deadlocks Caused by Locking Order</h3>


inspired by an article at 
<a href="http://hemantoracledba.blogspot.com/2010/09/deadlocks-2-deadlock-on-insert.html">Deadlocks : 2 -- Deadlock on INSERT</a>

The following scripts will demonstrate a deadlock on insert created by wrong locking order.

Two sqlplus sessions are required:

Create the test schema

  @create.sql


Session 1:

  @t1

Session 2:

  @t2

Session 2:

 press <ENTER>

now quickly go to Session 1 and press <ENTER>

One of the sessions will end in deadlock every time.

  insert into table_1 values (2,'S2')
  *
  ERROR at line 1:
  ORA-00060: deadlock detected while waiting for resource
  

Why does this happen?

It is because each session is holding a lock for a particular primary key,
and each is trying to obtain the lock the other has on the same primary key.


Now try the experiment using t3.sql rather than t2.sql

There will never be a deadlock.  Why not?

Because the order of the SQL statements was changed in t3.sql

t2.sql 
	insert into table_2 values (2,'S2');
	insert into table_1 values (2,'S2');

t3.sql
	insert into table_1 values (2,'S2');
	insert into table_2 values (2,'S2');


These are the inserts in t1.sql
	insert into table_1 values (2,'S1');
	insert into table_2 values (2,'S1');


When t1.sql and t2.sql are run, the table locks are in a different order,
each session wants the lock the other has, deadlock results.

This does not happen when t1.sql and t3.sql are used, as the locking orders
are the same, and the deadlock does not occur.


