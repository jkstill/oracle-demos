pipeline functions
==================

I always forget how to to this.

Here is at least 1 example of using a pipeline function to return rows from a table.

See the Docs: [Pipelined Functions](https://docs.oracle.com/en/database/oracle/oracle-database/21/lnpls/plsql-optimization-and-tuning.html#GUID-6C5DE334-7A63-41A3-BB4C-7B32CBF5607E)

## Pipelined Package

It is not necessary to create physical types in the database to use pipelined.

Several online examples seem to suggest this is the case, but it is not.

For simple cases such as when there is only 1 reference to the type being returned by the function, there is no need for extra objects.

If there are several places in different code files that all refer to the same types, then database type objects are useful.




