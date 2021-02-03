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

### prize-code-sum-function.sql

### prize-code-sum-function-test.sql


