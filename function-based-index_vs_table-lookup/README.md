Remediate Wrong Index Used
==========================

When the 'wrong' index is used for a SQL query, it is sometimes a struggle to coerce Oracle to again use the correct index.

There are many possible reasons for this, and I won't be trying to discuss them all here.

The particulars for this case:

- Wrong index chosen - execution time went from 0.01 seconds to 0.42 seconds
 - This has a very bad effect on performance when this SQL is called thousands of times
- One of the predicates in the WHERE clause uses a PL/SQL function
- This is a 3rd party application - we could not make changes to SQL

Looking for a quick win, we first ran a Tuning Task Report. 

Oracle recommended creating a Baseline, so we tried that.

In this case however, attempting to create the Baseline resulted in an error, ORA-13846:

```text

SQL# host  oerr ora 13846
13846, 00000, "Cannot create SQL plan baseline on the given plan"
// *Cause: There are either multiple plans exist for the given value or the
//         plan is not reproducible.
// *Action: Call Oracle Support.

```

A search of this error on My Oracle Support revealed ... nothing.

A search for that error did not bring back any results.

A couple of things led us to believe this was likely to be a bug

- 'Action: Call Oracle Support'
- This was Oracle 12.1.0.2, and unpatched

Could this problem have been fixed by updating statistics on the affected tables and indexes?

That is possible, and I believe quite likely.

However, there were several things beyond our control that day, and we had to work within our means.

One thing was certain: when a particular query was run, we knew which index it always should use.

The solution we came up with: use `dbms_diag_internal.i_create_sql_patch`.

This is a package that allows specifying a hint that should be used for a particular SQL statement.

When we did this, new executions of the SQL statement began using the correct index, and performance was restored.

For Oracle 12.2 and later, the procedure to use is `dbms_diag.create_sql_patch`.

One of the following demonstrations is a recreation of the issue encountered that day with some similar test data.

After showing the problem, I will show it can be remediated with a SQL Patch.

But, that is not all.  

There will also be two other demonstrations, both of which are things that could not be implemented that day, but are actually more effective.

While the production database was 12.1.0.2, the following demonstrations are being done on Oracle 19.8.0.

Let's get on with the demos.

## Building the Test Data

The hardest part of creating a reproducible test case is often just creating a data set that can be used to replicate the problem.

While the data created here is used to show the issue, I was not able to get the data to reproduce the issue without 'cheating' a bit, as you shall see.

First, create the table `func_test`.

```sql

create table func_test (
   comp_id number,
   comp_name varchar2(20),
   pay_id number,
   credit_id number,
   period_end_date date,
   trans_type varchar2(1),
   status varchar2(10),
   rval number,
   c1 varchar2(20),
   c2 varchar2(20),
   c3 varchar2(20)
);
```

The next step is to create some test data.

This SQL will create 2.5M rows.

```sql

insert into func_test
with companies as (
   select
      level company_id,
      dbms_random.string('L', 10) company_name
   from dual
   connect by level <= 100
),
payids as (
   select level pay_id
   from dual
   connect by level <= 5000
),
credit_ids as (
   select level credit_id
   from dual
   connect by level <= 5
)
select
   c.company_id
   , c.company_name
   , p.pay_id
   , ci.credit_id
   ,case trunc(dbms_random.value(1,5))
      when 1 then to_date('2020-03-31','yyyy-mm-dd')
      when 2 then to_date('2020-06-30','yyyy-mm-dd')
      when 3 then to_date('2020-09-30','yyyy-mm-dd')
      when 4 then to_date('2020-12-31','yyyy-mm-dd')
   end period_end_date
   , substr('ABCD',trunc(dbms_random.value(1,5)),1) trans_type
   , decode(mod(rownum,3),0,'ACTIVE',1,'INACTIVE',2,'PENDING') status
   , trunc(dbms_random.value(1,1000)) rval
   , dbms_random.string('L', 20) c1
   , dbms_random.string('L', 20) c2
   , dbms_random.string('L', 20) c3
from companies c
   ,payids p
   , credit_ids ci;

```

Once the data is created, the indexes are added:

```sql
create index  comp_id_idx on func_test(comp_id, pay_id);
create index  bad_idx on func_test(rval, period_end_date);
```

And now for the part where I cheat:  the index statistics are manipulated so the Oracle optimizer will favor the 'bad' index.

```sql
begin

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
```

Here are how the table and index statistics look:

```text
SQL# @show-stats

OBJECT_NAME                    OBJEC LAST_ANALYZED           BLOCKS   NUM_ROWS
------------------------------ ----- ------------------- ---------- ----------
FUNC_TEST                      TABLE 2021-01-15 10:34:12      38657    2500000
BAD_IDX                        INDEX 2021-01-15 10:34:36          8        100
COMP_ID_IDX                    INDEX 2021-01-15 10:34:36      32000   10000000

3 rows selected.
```

You can see where the optimizer is being lied to.

The COMP_ID_IDX index is made to look more expensive than it really is by setting blocks to 32000, and the number of rows to 10M.

Conversely, the BAD_IDX index has made to appear the right choice, as it has been made to appear as having only 8 blocks and 100 rows.

## The Test Query

Here is the test query that will be used.

```sql

-- dbms_xplan will not work properly when serveroutput is enabled
set serveroutput off

var period_end_date varchar2(10)
var comp_id number
var pay_id number

-- set bind variables for where clause
begin
   :period_end_date := '2020-06-30';
   :comp_id := 42;
   :pay_id := 37;
end;
/

select count(*)
from (
select /*+ gather_plan_statistics */
   rval, is_prime(rval) rprime
from func_test ft
where ft.comp_id = :comp_id
   and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')
   and ft.trans_type = 'B'
   and ft.status = 'ACTIVE'
   and is_prime(rval) = 'Y'
)
/

```

You may be wondering about `is_prime(rval)`, which is found in both the projection (columns selected) and as a predicate (WHERE clause).

The RVAL column was created with a random integer in the range 1-999.

The `is_prime()` function is called to determine if value is prime. The purpose is to simulate what was seen in a real application.

The `is_prime()` code is a rather brute force prime detector, but as the largest integer evaluated will be 999, it doesn't take long to run.

```sql
create or replace function is_prime ( prime_test_in integer ) 
return varchar2 deterministic
   is
      i integer;
      is_a_prime_number boolean;
      prime_number integer;
   begin
      
      -- obviously prime
      if prime_test_in = 2
         or prime_test_in = 3
         or prime_test_in = 5
         or prime_test_in = 7
      then
         return 'Y';
      elsif prime_test_in = 1
      then
         return 'N';
      elsif mod(prime_test_in,2) = 0
      then
         return 'N';
      elsif mod(prime_test_in,3) = 0
      then
         return 'N';
      elsif mod(prime_test_in,5) = 0
      then
         return 'N';
      elsif mod(prime_test_in,7) = 0
      then
         return 'N';
      end if;

      -- brute force prime detection
      i := 11;
      loop
         i := i + 2;

         if i > prime_test_in / 2 then
            exit;
         end if;

         if mod(prime_test_in,i) = 0 then
            return 'N';
         end if;
      end loop;
      
      return 'Y' ;
   end;
/
```

Evaluating all primes in the 1-999 range takes 10 milliseconds:

```
SQL# l
  1  declare
  2     v_is_prime varchar2(1);
  3  begin
  4     for i in 1..999
  5     loop
  6             v_is_prime := is_prime(i);
  7     end loop;
  8* end;
SQL# /

PL/SQL procedure successfully completed.

Elapsed: 00:00:00.01
```

## The First Test

Now we can run the SQL and see what we are up against.

Note: Both the Shared Pool and Buffer Cache are flushed between tests.  Please DO NOT do this in a production database.

The `showplan_last.sql` script is used to run `dbms_xplan.display_cursor` for the most recently run SQL in a SQLPlus session.

```
SQL# @@flush
System altered.
System altered.

SQL# @@q1

  COUNT(*)
----------
        83

1 row selected.

Elapsed: 00:00:13.16
```

At 13.16 seconds, this is not exactly a speedy query. The users are expecting something in the order of 0.5 seconds.

We can look at the execution plan to see why that is:

```text

SQL# @@showplan_last

PLAN_TABLE_OUTPUT
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  00v5ashkdhw9n, child number 0
-------------------------------------
select count(*) from ( select /*+ gather_plan_statistics */    rval,
is_prime(rval) rprime from func_test ft where ft.comp_id = :comp_id
and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')    and
ft.trans_type = 'B'    and ft.status = 'ACTIVE'    and is_prime(rval) =
'Y' )

Plan hash value: 2716387093

-----------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name      | Starts | E-Rows |E-Bytes| Cost (%CPU)| E-Time   | A-Rows |   A-Time   | Buffers | Reads  |
-----------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |           |      1 |        |       |    18 (100)|          |      1 |00:00:13.08 |     109K|  40210 |
|   1 |  SORT AGGREGATE                      |           |      1 |      1 |    26 |            |          |      1 |00:00:13.08 |     109K|  40210 |
|*  2 |   TABLE ACCESS BY INDEX ROWID BATCHED| FUNC_TEST |      1 |      5 |   130 |    18   (0)| 00:00:01 |     83 |00:00:00.41 |     109K|  40210 |
|*  3 |    INDEX SKIP SCAN                   | BAD_IDX   |      1 |    100 |       |    10   (0)| 00:00:01 |    105K|00:00:06.09 |    4491 |   4035 |
-----------------------------------------------------------------------------------------------------------------------------------------------------

Query Block Name / Object Alias (identified by operation id):
-------------------------------------------------------------

   1 - SEL$F5BB74E1
   2 - SEL$F5BB74E1 / FT@SEL$2
   3 - SEL$F5BB74E1 / FT@SEL$2

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter(("FT"."COMP_ID"=:COMP_ID AND "FT"."TRANS_TYPE"='B' AND "FT"."STATUS"='ACTIVE'))
   3 - access("FT"."PERIOD_END_DATE"=TO_DATE(:PERIOD_END_DATE,'yyyy-mm-dd'))
       filter(("FT"."PERIOD_END_DATE"=TO_DATE(:PERIOD_END_DATE,'yyyy-mm-dd') AND "IS_PRIME"("RVAL")='Y'))

Column Projection Information (identified by operation id):
-----------------------------------------------------------

   1 - (#keys=0) COUNT(*)[22]
   3 - "FT".ROWID[ROWID,10]


39 rows selected.

```

To begin with, look at the estimated rows (E-Rows) in the plan: it is 100.  This is evidence of the made up statistics where we tell Oracle that this index is on 100 rows.

The actual rows (A-Rows) is 105,000.  And for each of those rows, the `is_prime()` function was called.

How do we know the function was called that many times?  After all, that doesn't show up in a 10046 trace.

One way is to remove the use of the function, and rerun the query:

```text

@@flush
System altered.
System altered.
Session altered.

  1  select count(*)
  2  from (
  3  select /*+ gather_plan_statistics */
  4     rval -- , is_prime(rval) rprime
  5  from func_test ft
  6  where ft.comp_id = :comp_id
  7     and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')
  8     and ft.trans_type = 'B'
  9     and ft.status = 'ACTIVE'
 10     --and is_prime(rval) = 'Y'
 11* )
SQL# /

  COUNT(*)
----------
       508

1 row selected.

Elapsed: 00:00:08.90
```

That was significantly quicker that before - 8.9 seconds vs 13.16 seconds.

```text

SQL# @showplan_last

PLAN_TABLE_OUTPUT
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  d6tz6hqp3yutw, child number 0
-------------------------------------
select count(*) from ( select /*+ gather_plan_statistics */    rval --
, is_prime(rval) rprime from func_test ft where ft.comp_id = :comp_id
 and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')    and
ft.trans_type = 'B'    and ft.status = 'ACTIVE'    --and is_prime(rval)
= 'Y' )

Plan hash value: 2716387093

-----------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name      | Starts | E-Rows |E-Bytes| Cost (%CPU)| E-Time   | A-Rows |   A-Time   | Buffers | Reads  |
-----------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |           |      1 |        |       |    18 (100)|          |      1 |00:00:01.46 |     625K|   2276 |
|   1 |  SORT AGGREGATE                      |           |      1 |      1 |    22 |            |          |      1 |00:00:01.46 |     625K|   2276 |
|*  2 |   TABLE ACCESS BY INDEX ROWID BATCHED| FUNC_TEST |      1 |    521 | 11462 |    18   (0)| 00:00:01 |    508 |00:00:03.21 |     625K|   2276 |
|*  3 |    INDEX SKIP SCAN                   | BAD_IDX   |      1 |    100 |       |    10   (0)| 00:00:01 |    625K|00:00:00.27 |    4009 |      0 |
-----------------------------------------------------------------------------------------------------------------------------------------------------

Query Block Name / Object Alias (identified by operation id):
-------------------------------------------------------------

   1 - SEL$F5BB74E1
   2 - SEL$F5BB74E1 / FT@SEL$2
   3 - SEL$F5BB74E1 / FT@SEL$2

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter(("FT"."COMP_ID"=:COMP_ID AND "FT"."TRANS_TYPE"='B' AND "FT"."STATUS"='ACTIVE'))
   3 - access("FT"."PERIOD_END_DATE"=TO_DATE(:PERIOD_END_DATE,'yyyy-mm-dd'))
       filter("FT"."PERIOD_END_DATE"=TO_DATE(:PERIOD_END_DATE,'yyyy-mm-dd'))

Column Projection Information (identified by operation id):
-----------------------------------------------------------

   1 - (#keys=0) COUNT(*)[22]
   3 - "FT".ROWID[ROWID,10]

```

The A-Rows incresed dramatically, as predicate `is_prime(rval)` was removed.

Even so, the query now completes in 4.26 seconds quicker, as the overhead of calling the function has been removed.

Most of this issue is due to the choice of index made by the optimizer.

While the query returns only 83 rows, 105k rows were scanned in the index to narrow down that choice

The column list for BAD_IDX is (rval,trans_type)`.

The column list for the COMP_ID_IDX index is `(comp_id, pay_id)`.

As the first predicate for the query is on `comp_id`, and there are 100 distinct comp_id values, we would expect that index to be a better choice.

So as you may recall, at this time we could not do anything with optimizer statistics. 

As this is a 3rd party app, we could not alter the SQL, nor could be create an index. While creating an index might be a good choice if given sufficient time for testing, this was an emergency fix situation, so something else was called for.


## Hinting the SQL

The next we can do is hint the SQL to tell the optimizer we wnat to use a different index.

You may be wondering why the hint was not placed in the part of the query where it it will be used, like this:



```sql
  4  select /*+ gather_plan_statistics index(ft comp_id_idx)*/
  5     rval, is_prime(rval) rprime
  6  from func_test ft
```

As it is, the hint requires specifying the query block, which is a bit of extra trouble.

This will be explained a little later.


```sql
SQL# @flush
System altered.
System altered.
Session altered.

SQL# get afiedt.buf
  1  select /*+ index(@"SEL$2" "FT" "COMP_ID_IDX") */
  2     count(*)
  3  from (
  4  select /*+ gather_plan_statistics */
  5     rval, is_prime(rval) rprime
  6  from func_test ft
  7  where ft.comp_id = :comp_id
  8     and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')
  9     and ft.trans_type = 'B'
 10     and ft.status = 'ACTIVE'
 11     and is_prime(rval) = 'Y'
 12* )
SQL# /

  COUNT(*)
----------
        83

1 row selected.

Elapsed: 00:00:00.47
```

That is quite a substantial improvement.  From 13 seconds to 0.47 seconds.

And here's why:

```text

-------------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name        | Starts | E-Rows |E-Bytes| Cost (%CPU)| E-Time   | A-Rows |   A-Time   | Buffers | Reads  |
-------------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |             |      1 |        |       | 10331 (100)|          |      1 |00:00:00.24 |     960 |    479 |
|   1 |  SORT AGGREGATE                      |             |      1 |      1 |    26 |            |          |      1 |00:00:00.24 |     960 |    479 |
|*  2 |   TABLE ACCESS BY INDEX ROWID BATCHED| FUNC_TEST   |      1 |      5 |   130 | 10331   (1)| 00:00:01 |     83 |00:00:00.21 |     960 |    479 |
|*  3 |    INDEX RANGE SCAN                  | COMP_ID_IDX |      1 |    100K|       |   326   (1)| 00:00:01 |  25000 |00:00:00.09 |      66 |     66 |
-------------------------------------------------------------------------------------------------------------------------------------------------------

```

The A-Rows value has been reduced from 105k to 25k.

But more importantly, the `is_prime(rval)` function is no longer being called for every evaluated row.

Just how important is that?  Let's perform a test to find out.

Earlier you saw a test where `is_prime()` evalated all digits in the range of 1..999 for prime.

That ran in 0.01 seconds.

Let's run a similar test, but now run it 105k times.

```sql
declare
   v_is_prime varchar2(1);
begin
   for j in 1..105
   loop
      for i in 1..999
      loop
         v_is_prime := is_prime(i);
      end loop;
   end loop;
end;

SQL# /

Elapsed: 00:00:00.74

```

As you can see, it is still quite fast.

But, let's change it to more closely simulate what is occurring with the SQL statement.

This time, rather than a direct assignment, the value will be assigned via `select X into Y from dual`.


```sql

declare
   v_is_prime varchar2(1);
begin
   for j in 1..105
   loop
      for i in 1..999
      loop
         select is_prime(i) into v_is_prime from dual;
      end loop;
   end loop;
end;

SQL# /

Elapsed: 00:00:04.92

```

Now the time required is very close to the time required to scan the BAD_IDX index when the query took 13 seconds.

6 seconds of the query time was scanning that index.

When we removed the parts of the sql that called the `is_prime(rval)` function, the index scan time took only 0.27 seconds

The rest of the time was due to calling the `is_prime(rval)` function.

As shown in the tests, when switching from direct assignment to the variable `v_is_prime` to assignment by `select from dual`, the decrease in performance was 7x. 

The same thing is happening in the test query.

The context switch between SQL and PL/SQL (calling the function) is very expensive.

## SQL Patch

Now we know why the query is so slow.

While the Developer in me thinks that using a function in a WHERE clause is pretty cool, the DBA and Performance Analyst side of thinks it looks like a serious potential performance issue (it is).

Nonetheless, this is what we have to work with.

At this point it was decided to use `dbms_diag_internal.i_create_sql_patch`, so that we could provide a hint to the optimizer, telling it to use our preferred index.

Following is a simplified version of the script. 

And that brings us to the hint with the query block included.

It is necessary to tell `sql_patch` which part of the query the hint applies to.

And so the hint was first tested, to ensure it worked.

The real script checks for patch existence and possibly and other niceties, but for the purposes of this article, I am keeping it brief.

```sql

SYS@pdb1 AS SYSDBA>
declare
   v_sql_id varchar2(13);
   v_patch_name varchar2(2000);
begin
   v_sql_id := :b_sql_id;
   -- if prior to 12.2
   -- dbms_sqldiag_internal.i_create_sql_patch
   v_patch_name :=  dbms_sqldiag.create_sql_patch(
      sql_id  => v_sql_id,
      hint_text => 'index(@"SEL$2" "FT" "COMP_ID_IDX")',
      --hint_text => 'gather_plan_statistics',
      name      => 'ft_' || v_sql_id
   );
   dbms_output.put_line('patch name: ' || v_patch_name);
end;
 16  /
patch name: ft_00v5ashkdhw9n

PL/SQL procedure successfully completed.

```

Did it work? Yes, it did.

```sql

SQL# get afiedt.buf
  1  select count(*)
  2  from (
  3  select /*+ gather_plan_statistics */
  4     rval, is_prime(rval) rprime
  5  from func_test ft
  6  where ft.comp_id = :comp_id
  7     and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')
  8     and ft.trans_type = 'B'
  9     and ft.status = 'ACTIVE'
 10     and is_prime(rval) = 'Y'
 11* )
SQL# /

  COUNT(*)
----------
        83

1 row selected.

Elapsed: 00:00:00.49

```

The time of 0.49 is quite an improvement on 13 seconds.

The execution plan shows us why it was now so fast:

```text
SQL# @showplan_last

Plan hash value: 1388359396

-------------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name        | Starts | E-Rows |E-Bytes| Cost (%CPU)| E-Time   | A-Rows |   A-Time   | Buffers | Reads  |
-------------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |             |      1 |        |       | 10331 (100)|          |      1 |00:00:00.24 |     960 |    478 |
|   1 |  SORT AGGREGATE                      |             |      1 |      1 |    26 |            |          |      1 |00:00:00.24 |     960 |    478 |
|*  2 |   TABLE ACCESS BY INDEX ROWID BATCHED| FUNC_TEST   |      1 |      5 |   130 | 10331   (1)| 00:00:01 |     83 |00:00:00.21 |     960 |    478 |
|*  3 |    INDEX RANGE SCAN                  | COMP_ID_IDX |      1 |    100K|       |   326   (1)| 00:00:01 |  25000 |00:00:00.08 |      66 |     66 |
-------------------------------------------------------------------------------------------------------------------------------------------------------

Total hints for statement: 1
---------------------------------------------------------------------------

   1 -  SEL$F5BB74E1
           -  index(@"SEL$2" "FT" "COMP_ID_IDX")

Note
-----
   - SQL patch "ft_00v5ashkdhw9n" used for this statement

```

It shows that SQL Path  "ft_00v5ashkdhw9n" was successfully used to provide a hint to use the index COMP_ID_IDX

While this did fix the issue in this database, that is not the end of the story.

## Alternatives

There are at least two alternatives that may be used to deal with this.

### Function Based Index

Though we could not create an index that day, it may be a consideration for the future, when proper testing can be done.

Oracle has the ability to create indexes based on a function.

The advantages to using this FBI (Function Based Index): 
- the values for `is_prime(rval)` are pre-computed in the index
- the index can then be used for the table row lookup

Here is our index DDL:
```sql
create index func_test_fbi_idx on func_test(comp_id,pay_id, is_prime(rval))
```

The database statistics will be re-gathered (without lying to the optimzer), the index built, and the test query re-run.

```text
  1  begin
  2     dbms_stats.delete_table_stats(ownname => user, tabname => 'FUNC_TEST', cascade_indexes => true);
  3     dbms_stats.gather_table_stats(ownname => user, tabname => 'FUNC_TEST');
  4     dbms_stats.gather_index_stats(user,'BAD_IDX');
  5     dbms_stats.gather_index_stats(user,'COMP_ID_IDX');
  6* end;
  7  /

Elapsed: 00:00:09.51

SQL# create index func_test_fbi_idx on func_test(comp_id,pay_id, is_prime(rval));

Index created.

Elapsed: 00:00:46.54

SQL# @show-stats

OBJECT_NAME                    OBJEC LAST_ANALYZED           BLOCKS   NUM_ROWS
------------------------------ ----- ------------------- ---------- ----------
FUNC_TEST                      TABLE 2021-01-15 13:49:06      38657    2500000
BAD_IDX                        INDEX 2021-01-15 13:49:14       8306    2500000
COMP_ID_IDX                    INDEX 2021-01-15 13:49:15       6336    2500000
FUNC_TEST_FBI_IDX              INDEX 2021-01-15 13:51:07       6958    2500000

```

Drop the SQL Patch:

```sql

SQL# exec dbms_sqldiag.drop_sql_patch(name => 'ft_00v5ashkdhw9n' )

PL/SQL procedure successfully completed.

```


Now, rerun the test query.

```text
SQL# @flush
System altered.
System altered.
Session altered.

SQL# l
  1  select count(*)
  2  from (
  3  select /*+ gather_plan_statistics */
  4     rval, is_prime(rval) rprime
  5  from func_test ft
  6  where ft.comp_id = :comp_id
  7     and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')
  8     and ft.trans_type = 'B'
  9     and ft.status = 'ACTIVE'
 10     and is_prime(rval) = 'Y'
 11* )

#SQL /

  COUNT(*)
----------
        83

1 row selected.

Elapsed: 00:00:00.34
```

This is the fastest exeuction yet.  Let's take a look at the execution plan:

```text
SQL# @showplan_last


Plan hash value: 2498653831

-------------------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name              | Starts | E-Rows |E-Bytes| Cost (%CPU)| E-Time   | A-Rows |   A-Time   | Buffers | Reads  |
-------------------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |                   |      1 |        |       |    75 (100)|          |      1 |00:00:00.25 |     462 |    458 |
|   1 |  SORT AGGREGATE                      |                   |      1 |      1 |   106 |            |          |      1 |00:00:00.25 |     462 |    458 |
|*  2 |   TABLE ACCESS BY INDEX ROWID BATCHED| FUNC_TEST         |      1 |      5 |   530 |    75   (0)| 00:00:01 |     83 |00:00:00.10 |     462 |    458 |
|*  3 |    INDEX RANGE SCAN                  | FUNC_TEST_FBI_IDX |      1 |    100 |       |    72   (0)| 00:00:01 |   4220 |00:00:00.01 |      73 |     73 |
-------------------------------------------------------------------------------------------------------------------------------------------------------------

Query Block Name / Object Alias (identified by operation id):
-------------------------------------------------------------

   1 - SEL$F5BB74E1
   2 - SEL$F5BB74E1 / FT@SEL$2
   3 - SEL$F5BB74E1 / FT@SEL$2

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter(("FT"."TRANS_TYPE"='B' AND "FT"."STATUS"='ACTIVE' AND "FT"."PERIOD_END_DATE"=TO_DATE(:PERIOD_END_DATE,'yyyy-mm-dd')))
   3 - access("FT"."COMP_ID"=:COMP_ID AND "FT"."SYS_NC00012$"='Y')
       filter("FT"."SYS_NC00012$"='Y')

Column Projection Information (identified by operation id):
-----------------------------------------------------------

   1 - (#keys=0) COUNT(*)[22]
   3 - "FT".ROWID[ROWID,10], "FT"."SYS_NC00012$"[VARCHAR2,4000]
```

The number of A-Rows scanned has been greatly reduced, from 25000 down to 4220.

In addition, you may have notice the filter `FT"."SYS_NC00012$"='Y'`. What's that?

Creating a function based index has caused Oracle to create an invisible column in the test table:

```text
SQL# col column_name format a20
SQL# l
  1  select
  2     column_id
  3     , column_name
  4     , nullable
  5     , hidden_column
  6  from user_tab_cols
  7  where table_name = 'FUNC_TEST'
  8* order by column_id
SQL# /

 COLUMN_ID COLUMN_NAME          N HID
---------- -------------------- - ---
         1 COMP_ID              Y NO
         2 COMP_NAME            Y NO
         3 PAY_ID               Y NO
         4 CREDIT_ID            Y NO
         5 PERIOD_END_DATE      Y NO
         6 TRANS_TYPE           Y NO
         7 STATUS               Y NO
         8 RVAL                 Y NO
         9 C1                   Y NO
        10 C2                   Y NO
        11 C3                   Y NO
           SYS_NC00012$         Y YES

12 rows selected.
```

As the saying goes, there is no free lunch. That precomputed value had to be stored, and Oracle has stored it in hidden column  SYS_NC00012$.

```text
  1* select SYS_NC00012$ from func_test where rownum < 11
SQL# /

SYS_NC00012$
-------------
N
N
N
N
N
N
N
N
N
Y

10 rows selected.
```

The reduction in CPU usage may well make this a worthwhile tradeoff, that is, trading a little space for a significant performance increase.


### Design Changes

As this is a 3rd party app, we cannot make any design decisions.

If you are in a position to suggest design changes however, you may want to consider this section as well.

In general, using functions within a SQL statement is not optimal for database performance.

What if rather than using a function, a lookup table were used instead?

I can hear the groans now: "Adding a join? Joins are slow!"

The truth is, joins are not slow. If there is one thing Oracle does well, it is joining tables.

However, it is very easy to design tables and SQL statements in such a way that joins are very slow.

Actually, it is not that joins are slow, it is simply that the design of the tables, indexes and SQL cant lead to performance issues due when far too many rows are being considered.

But, that is not the point of this article.

Let's create a table PRIMES, that consists of all primes found in the range of 1..999.

```sql
create table primes
   prime_number integer not null,
   constraint pk_prime primary key (prime_number)
) organization index;
```

The code to populate this is not explained here, as it would lead to a rather lengthy side tracking of the main topic.

We now have the first 168 primes:

```text
-- gather stats
#SQL exec dbms_stats.gather_table_stats(ownname => user, tabname => 'PRIMES')

#SQL @@show-stats

OBJECT_NAME                    OBJEC LAST_ANALYZED           BLOCKS   NUM_ROWS
------------------------------ ----- ------------------- ---------- ----------
FUNC_TEST                      TABLE 2021-01-15 13:49:06      38657    2500000
BAD_IDX                        INDEX 2021-01-15 13:49:14       8306    2500000
COMP_ID_IDX                    INDEX 2021-01-15 13:49:15       6336    2500000
PK_PRIME                       INDEX 2021-01-15 14:37:51          1        168

4 rows selected.

```

Now that we have the primes, we can drop the Function Based Index, and rewrite the query to avoid the use of the `is_prime(rval)` function in the predicate.

```text

SQL# @flush
System altered.
System altered.
Session altered.

SQL# drop index func_test_fbi_idx;
Index dropped.

QL# get afiedt.buf
  1  select count(*)
  2  from (
  3  select /*+ gather_plan_statistics */
  4     rval, 'Y' rprime
  5  from func_test ft
  6  join primes pf on pf.prime_number = ft.rval
  7  where ft.comp_id = :comp_id
  8     and ft.period_end_date = to_date(:period_end_date,'yyyy-mm-dd')
  9     and ft.trans_type = 'B'
 10     and ft.status = 'ACTIVE'
 11     --and is_prime(rval) = 'Y'
 12* )
SQL# /

  COUNT(*)
----------
        83

1 row selected.

Elapsed: 00:00:00.25
```

The execution time is the fastest yet.

What is especially nice is there is no chance of that function being used in the predicate.

Notice too that there is need to use the `is_prime(rval)` in the column projection either, as the only rows returned are those where rval is prime.

The 

```text
SQL# @showplan_last

Plan hash value: 3520673696

--------------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                             | Name        | Starts | E-Rows |E-Bytes| Cost (%CPU)| E-Time   | A-Rows |   A-Time   | Buffers | Reads  |
--------------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                      |             |      1 |        |       |   505 (100)|          |      1 |00:00:00.19 |     482 |    453 |
|   1 |  SORT AGGREGATE                       |             |      1 |      1 |    30 |            |          |      1 |00:00:00.19 |     482 |    453 |
|   2 |   NESTED LOOPS                        |             |      1 |    215 |  6450 |   505   (1)| 00:00:01 |     83 |00:00:00.17 |     482 |    453 |
|*  3 |    TABLE ACCESS BY INDEX ROWID BATCHED| FUNC_TEST   |      1 |    521 | 13546 |   505   (1)| 00:00:01 |    508 |00:00:00.11 |     478 |    452 |
|*  4 |     INDEX RANGE SCAN                  | COMP_ID_IDX |      1 |  25000 |       |    66   (0)| 00:00:01 |  25000 |00:00:00.07 |      66 |     66 |
|*  5 |    INDEX UNIQUE SCAN                  | PK_PRIME    |    508 |      1 |     4 |     0   (0)|          |     83 |00:00:00.01 |       4 |      1 |
--------------------------------------------------------------------------------------------------------------------------------------------------------

```

This query exeucution plan is just slightly more complex than the others, but with an execution time of 0.25 seconds, it is clearly the fastest.

When it comes to performance issues, sometimes the most expedient choice is not the one you might prefer.

It is necessary to balance out the remediation with the current goals.

In this case the current goal was 'make the system usable so our users can do their jobs', making the use of a SQL Patch the best choice this day.

## Prologue

Well, I did cheat a little in this article.

While the situation shown is relatively close to what was really seen, and the method used was identical, there was a slight diffference in the real production table.

The column being passed to the function was not a simple integer, it was a nested table.

How can you deal with that?

More to come...



## QuickStart SQL Patch Demo

Do NOT do this in any production databaes, as the `flush.sql` does just what you should expect it to: it flushes the Shared Pool and the Buffer Cache.

```text
@@schema.sql
@@stats-fake
@@flush
set autotrace on
-- should use bad_idx index
@@q1 
set autotrace off
@@sql-patch
@@flush
set autotrace on
-- should use comp_id_idx
@@q1 
set autotrace off
-- create FBI index
@@fbi 
@@stats-std
@@flush
set autotrace on
-- should use the new FBI index
@@q1 
set autotrace off
```



