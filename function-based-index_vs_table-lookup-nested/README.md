Remediate Wrong Index Used
==========================

WIP!

This is a followup to the blog post that uses SQL_PATCH

see ../function-based-index_vs_table-lookup

This will be similar, but now selection criteria is not a single value, but several values found in nested tale.

Some files have not yet been modified for the new test, and will not work

## Schema

Now using an object type to create a nested table column 'PRIZE_CODES'.

This replaces the 'RVAL' column used in the previous example
  ../function-based-index_vs_table-lookup

The insert creates 3 rows in each nested table.

## Querying the table

See the nt-select*.sql scripts.

## Function prize_code_sum

There are two versions of this function.

One of them is much faster than the other.

Use the two files to create different versions of the function, and test with `q5.sql`.


### prize-code-sum-function.sql

This version uses `select code_num from table(codes_in)`.

Here is the code:

```sql
create or replace function prize_code_sum ( codes_in prize_code_nt )
return integer deterministic
is
	i_sum pls_integer := 0;

begin
	for pzrec in (
		select code_num
		from table(codes_in)
	)
	loop
		i_sum := i_sum + pzrec.code_num;
	end loop;
	return i_sum;
end;
```

And here is a test with 2.5M rows:

```text

#SQL get q5

  1  with data as  (
  2     select /*+ first_rows(100) */
  3             f.comp_id
  4             , f.pay_id
  5             , f.credit_id
  6             -- the column in the PRIZE_CODE_OBJ_TYP
  7             , f.prize_codes
  8     from func_test_prize f
  9     where prize_code_sum(prize_codes) = 42
 10     --where rownum <= 1e6
 11  )
 12  select count(*) from (
 13  select comp_id, pay_id, credit_id,
 14     prize_code_sum(prize_codes)
 15  from data
 16* )
#SQL /

  COUNT(*)
----------
     64003

1 row selected.

Elapsed: 00:02:24.28

```

### prize-code-sum-function-test.sql

Here is the function code, this time using a nested table iterator:

```sql
create or replace function prize_code_sum ( codes_in prize_code_nt )
return integer deterministic
is
   i_sum pls_integer := 0;
   v_str varchar2(200);
begin
   for pz_index in codes_in.first .. codes_in.last
   loop
      i_sum := i_sum + codes_in(pz_index).code_num;
   end loop;
   return i_sum;
end;
```

And again, a test with 2.5M rows:


```text

#SQL @q5

  COUNT(*)
----------
     64003

1 row selected.

Elapsed: 00:00:42.08
```

Running that again later it completed in 26 seconds.

### Conclusion on functions and procedures with SELECT

Avoid using SELECT if it is not needed.

The context switch between SQL and PL/SQL is expensive, as can be seen in the timing differences.

## Function Based Index

Now I can create a function based index, using the `prize_code_sum` function:

```sql

Index created.

Elapsed: 00:01:01.71
```

This time the test script `q5.sql` is a bit quicker.

```text
SQL# @q5

  COUNT(*)
----------
     64003

1 row selected.

Elapsed: 00:00:01.76
```

Subsequent executions were even faster:

```text
SQL# /

  COUNT(*)
----------
     64003

1 row selected.

Elapsed: 00:00:00.09
```

The function based index has made quite a difference in performance for this test statement.

But, can it be made faster?  

How fast is 'fast enough'?

If there is a way to make it faster, it is worthing knowing about.

## Faster?

We have not previously looked at the execution plan with the index, so here it is:

```text
PLAN_TABLE_OUTPUT
--------------------------------------
SQL_ID  cfp7tj20jkgpq, child number 0
-------------------------------------
with data as  (  select /*+ first_rows(100) */   f.comp_id   , f.pay_id
  , f.credit_id   -- the column in the PRIZE_CODE_OBJ_TYP   ,
f.prize_codes  from func_test_prize f  where
prize_code_sum(prize_codes) = 42  --where rownum <= 1e6 ) select
count(*) from ( select comp_id, pay_id, credit_id,
prize_code_sum(prize_codes) from data )

Plan hash value: 394335527

------------------------------------------------------------------------------------------------
| Id  | Operation             | Name                  | E-Rows |E-Bytes| Cost (%CPU)| E-Time   |
------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT      |                       |        |       |  2383 (100)|          |
|   1 |  SORT AGGREGATE       |                       |      1 |    13 |            |          |
|*  2 |   INDEX FAST FULL SCAN| FUNC_TEST_PRZ_FBI_IDX |  93765 |  1190K|  2383  (16)| 00:00:01 |
------------------------------------------------------------------------------------------------

Query Block Name / Object Alias (identified by operation id):
-------------------------------------------------------------

   1 - SEL$DA6C289E
   2 - SEL$DA6C289E / F@SEL$1

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("F"."SYS_NC00013$"=42)

Column Projection Information (identified by operation id):
-----------------------------------------------------------

   1 - (#keys=0) COUNT(*)[22]

Hint Report (identified by operation id / Query Block Name / Object Alias):
Total hints for statement: 1
---------------------------------------------------------------------------

   0 -  STATEMENT
           -  first_rows(100)

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)
   - Warning: basic plan statistics not available. These are only collected when:
       * hint 'gather_plan_statistics' is used for the statement or
       * parameter 'statistics_level' is set to 'ALL', at session or system level

49 rows selected.

```

Though the sql was fairly quick, it is still a INDEX FAST FULL SCAN.

Can we do better?






