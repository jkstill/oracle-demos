


This test was to see how much memory is used for sequence cache

Answer is in this doc:
Resolving Issues For Sequence Cache Management Causing Contention (Doc ID 1477695.1)

The amount used is always 4k (at least here)

All it does is set a max value in the instance.
The database is not revisited until the local value is maxed out.


---------------------------------------------------------

Create a sequence with increasing large cache.

Measure memory usage per cache size.

## Method

Create a table to store the metrics


- Create a Sequence with cache 0

In a loop

- alter sequence seqname cache N
- record the memory used from v$db_object_cache


