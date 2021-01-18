Hash Gen Demos
===============

When generating the MD5 hash and FULL\_HASH\_VALUE from SQL Text, the generated values do not match what is generated internally in the database, as seen in v$sql and v$db\_object\_cache

Demonstrate generating hash values outside of the oracle database.

Hypothesis: the matches that fail inside the db, will also fail outside the db

## Generating a Hash with OS utilities

Generate a full MD5 hash by appending chr(0) (NUL) to the sql hash.

On occasion it is necessary to append 2 NUL characters to the sql text.
It is unknown why that is so, but for this demonstration, that will be ignored.

- Write it to a file without an OS line terminator.
- Use md5sum to get the hash value

Here are 2 SQL statements; one is known to get a matching hash, the other does not

Files are created via `echo -en 'sqltext\x00' > filename`

MD5 Hashes are generated via `md5sum filename`

The SQL is inside | delimiters

Statement that does NOT fail:

  |delete from indpart$ where obj#=:1|

sql_id: 03vz9vw04fcmc
hash#: 4665964
  hex:  47326C
full_hash_value: d08c94f041dea09a01efe9df0047326c
  generated fhv: d08c94f041dea09a01efe9df0047326c
  gend md5 hash: F0948CD09AA0DE41DFE9EF016C324700

file: 03vz9vw04fcmc.txt

md5sum: f0948cd09aa0de41dfe9ef016c324700

The OS generated sum matches the dbms_crypto.hash generated sum.


Statement that DOES fail:

|delete /* QOSH:PURGE_OSS */ /*+ dynamic_sampling(4) */ from sys.opt_sqlstat$  where last_gather_time < least(:1, sysdate - :2/86400)  and rownum <=  :3  |

sql_id: 6sx1r7tgh2tu2
hash#: 1728580789
  hex:  67080CB5
full_hash_value: fd4eb687cc3fbf9e00dfa4de67080cb5
  generated fhv: 77f379685265277a6c74373e5f016742
  gend md5 hash: 6879F3777A2765523E37746C4267015F

file: 6sx1r7tgh2tu2.txt

md5sum: 6879f3777a2765523e37746c4267015f

The OS generated sum again matches the dbms_crypto.hash generated sum.



