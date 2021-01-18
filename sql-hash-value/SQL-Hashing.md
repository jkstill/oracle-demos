Hashing Oracle SQL Statements
=============================

Following are techniques for deriving the following for a SQL statement:

- The 16 Byte Hash Value
- The 32 Byte Full Hash Value
- The SQL ID


## Why Generate These Values?

There could be multiple reasons for generating these values on your own.

For instance, the dbms_shared_pool package has a procedure Markhot, which is useful when mitigating library cache contention with very frequently used SQL statements.

One of the required arguments for this package is the full_hash_value.

As of this writing, the full_hash_value appears in only 1 place that is available to DBAs:  the gv$db_object_cache view.

Let's as you find SQL that frequently appears in AWR along with 'cursor: pin S wait on X'.

And now you would like to use Markhot to ensure that SQL gets multiple copies in the future to reduce libcache contention.

Until that SQL appears in gv$db_object_cache, the full_hash_value is not available.

(The SQL being in v$sql or appearing in v$active_session_history does not guarantee it will be found in gv$db_object_cache)


If you can generate the value for full_hash_value, then you can proceed.

## Generating the full_hash_value

The good news is you can generate full_hash_value, directly from the SQL text.

The sql_id and hash_value can also be generated.


