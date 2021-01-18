Hashing Oracle SQL Statements
=============================

Following are techniques for deriving the following for a SQL statement:

- The 4 Byte Hash Value
- The 16 Byte Full Hash Value
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

Oracle Supplies a number of functions and procedures that may be used to get these values.

For the hash_value and full_hash_value, you may also write your own functions to derive these values.

These same methods can be used in Perl, Bash, Python, or any other language.


## Packages providing hash functions


Something to keep in mind is that oracle uses a terminating chr(0) at the end of the text to identify it as a SQL statement.

On occassion it is necessary to use 2 chr(0) values.

And sometimes, that does not work.

In addition, some of the functions will add that chr(0) for you.

The SQL used for the following tests: 'select dummy from dual'

```text
SQL# set serveroutput off
SQL# 
SQL# select dummy from dual
  2  /

D
-
X

1 row selected.

SQL# @showplan_last

PLAN_TABLE_OUTPUT
------------------------------------------------
SQL_ID  4au7rzs3y6kzn, child number 0
-------------------------------------
select dummy from dual

Plan hash value: 272002086

---------------------------------------------------------------------------
| Id  | Operation         | Name | E-Rows |E-Bytes| Cost (%CPU)| E-Time   |
---------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |        |       |     2 (100)|          |
|   1 |  TABLE ACCESS FULL| DUAL |      1 |     2 |     2   (0)| 00:00:01 |
---------------------------------------------------------------------------
```

The known sql_id is 4au7rzs3y6kzn


### dbms_sql_translator.sql_hash

There is no need (usually) to manually add the chr(0) value with this function.

Args: clob SQL text
Ret: number


Get the hash_value as decimal

```text

SQL# select dbms_sql_translator.sql_hash('select dummy from dual') from dual;

DBMS_SQL_TRANSLATOR.SQL_HASH('SELECTDUMMYFROMDUAL')
---------------------------------------------------
                                          132336628

```

Get the 16 bit hash value as hex

```text
SQL# select lpad(trim(to_char(dbms_sql_translator.sql_hash('select dummy from dual'),'XXXXXXXXXXXXXXX')),8,'0') from dual;

LPAD(TRIM(TO_CHAR(DBMS_SQL_TRANS
--------------------------------
07E34BF4

1 row selected.
```

Match to the value in v$sql

```text
SQL# select hash_value from v$sql where sql_id = '4au7rzs3y6kzn';

HASH_VALUE
----------
 132336628
```


### dbms_sql_translator.sql_id

There is no need (usually) to manually add the chr(0) value with this function.

Args: clob SQL text
Ret: varchar2

```text
SQL# select dbms_sql_translator.sql_id('select dummy from dual') from dual;

DBMS_SQL_TRANSLATOR.SQL_ID('SELECTDUMMYFROMDUAL')
--------------------------------------------------
4au7rzs3y6kzn
```
## dbms_utility.get_sql_hash

The get_sql_hash function returns the numeric hash_value, and can also return the full_hash_value via an out variable

A limitation of the dbms_utility.get_sql_hash function is that it only works correctly for SQL statements that are <4000 bytes in length, as the input is varchar2, not clob.

A chr(0) must be appended to the SQL text.

See dbms_utility-get_sql_hash

```text
  1  declare
  2     hash_value number;
  3     v_sql varchar2(100);
  4     r_full_hash_value raw(128);
  5     raw_pre10_hash number;
  6  begin
  7     v_sql := 'select dummy from dual';
  9        name => v_sql || chr(0)
 10        , hash => r_full_hash_value
 11        , pre10ihash => raw_pre10_hash
 12     );
 13     dbms_output.put_line('hash_value: ' || to_char(hash_value));
 14     dbms_output.put_line('full_hash_value: ' || r_full_hash_value);
 15* end;
 16  /
hash_value: 132336628
full_hash_value: ABF1CA51FB6B36A0FEF76845F44BE307

```

However, this hash value is not quite right:

```text
SQL# select distinct upper(full_hash_value) full_hash_value from v$db_object_cache where hash_value = 132336628;

FULL_HASH_VALUE
--------------------------------
51CAF1ABA0366BFB4568F7FE07E34BF4

1 row selected.

```

The bytes for the full_hash_value as seen in v$db_object_cache are reversed on 4 byte boundaries
Gen  Full Hash Value:  ABF1CA51 FB6B36A0 FEF76845 F44BE307
Real Full Hash Value:  51CAF1AB A0366BFB4 568F7FE 07E34BF4

So, here is how we can get the correct full_hash_value using dbms_utility_get_sql_hash:

```text
  1  declare
  2     hash_value number;
  3     v_sql varchar2(100);
  4     r_full_hash_value raw(16);
  5     corrected_full_hash_value raw(16);
  6     raw_pre10_hash number;
  7  begin
  8     v_sql := 'select dummy from dual';
  9     hash_value := dbms_utility.get_sql_hash(
 10        name => v_sql || chr(0)
 11        , hash => r_full_hash_value
 12        , pre10ihash => raw_pre10_hash
 13     );
 14     dbms_output.put_line('hash_value: ' || to_char(hash_value));
 15     dbms_output.put_line('full_hash_value: ' || r_full_hash_value);
 16     corrected_full_hash_value :=
 17        utl_raw.reverse(utl_raw.substr(r_full_hash_value,1,4)) ||
 18        utl_raw.reverse(utl_raw.substr(r_full_hash_value,5,4)) ||
 19        utl_raw.reverse(utl_raw.substr(r_full_hash_value,9,4)) ||
 20        utl_raw.reverse(utl_raw.substr(r_full_hash_value,13));
 21     dbms_output.put_line('corrected_full_hash_value: ' || corrected_full_hash_value);
 22* end;
 23  /
hash_value: 132336628
full_hash_value: ABF1CA51FB6B36A0FEF76845F44BE307
corrected_full_hash_value: 51CAF1ABA0366BFB4568F7FE07E34BF4
```

Now it the generated full_hash_value is correct - compare the Oracle created full_hash_value to the one created with our bit of PL/SQL:

```text
       Real Full Hash Value:  51CAF1AB A0366BFB4 568F7FE 07E34BF4
  corrected_full_hash_value:  51CAF1AB A0366BFB4 568F7FE 07E34BF4
```

These tests were performed on 64 bit Linux running on Intel processor.

The tests may work differently on big-endian platforms, in which case the dbms_utility.get_endianness function would be useful.

### dbms_crypto.hash

The dbms_crypto.hash function can return a hash without the varchar2 limitations found in dbms_utility.get_sql_hash.

See dbms_crypto-hash.sql

```text
  1  declare
  2     md5hash raw(16);
  3     full_hash_value raw(16);
  4     c_sql clob;
  5  begin
  6     c_sql := 'select dummy from dual';
  7
  8     md5hash :=
  9        rawtohex(
 10           dbms_crypto.hash(
 11              src =>c_sql||chr(0),
 12              typ => dbms_crypto.HASH_MD5
 13           )
 14        );
 15
 16     dbms_output.put_line('md5hash: ' || md5hash);
 17
 18     full_hash_value :=
 19        utl_raw.reverse(utl_raw.substr(md5hash,1,4)) ||
 20        utl_raw.reverse(utl_raw.substr(md5hash,5,4)) ||
 21        utl_raw.reverse(utl_raw.substr(md5hash,9,4)) ||
 22        utl_raw.reverse(utl_raw.substr(md5hash,13));
 23
 24     dbms_output.put_line('full_hash_value: ' || full_hash_value);
 25
 26* end;
SQL#
md5hash: ABF1CA51FB6B36A0FEF76845F44BE307
full_hash_value: 51CAF1ABA0366BFB4568F7FE07E34BF4

```

### dbms_obfuscation_toolkit.md5 (deprecated)

The dbms_obfuscation_toolkit.md5 function and procedures are of limited use, as they produce only the 4 byte hash_value, not the full 16 byte full_hash_value.

### Bash and md5sum

These values can also be created using only the md5sum program and a few Bash functions.

Create a text file of the SQL

```bash
echo -en 'select dummy from dual\x00' > dummy-from-dual.txt
```

Now run the `gen-fhv-demo.sh` script against the file:

```text
$  ./gen-fhv-demo.sh dummy-from-dual.txt
    md5: abf1ca51fb6b36a0fef76845f44be307
       generated fhv: 51caf1aba0366bfb4568f7fe07e34bf4
generated hash_value: 132336628
    generated sql_id: 4au7rzs3y6kzn
```

Please see the gen-fhv-demo.sh script for the code.

## The SQL_ID alphabet

The values used for the sql_id may be found by finding all distinct values of letters that occur in the string.

This can be done with the `sqlid-alphabet.sql` script as shown following:

```sql

SQL# @sqlid-alphabet.sql

0123456789abcdfghjkmnpqrstuvwxyz

```

This script works by scanning v$sql_area for the first 32 row, decomposing the sql_id values 1 character at a time.

Notably absent are the characters 'e', 'i', 'l' and 'o'.

With some fonts, 'i', 'l' and 'o' can all be difficult to distinguize from 1 or 0. 

I do not know why 'e' was chosen for exclusion.

This alphabet is then used as a map for generating sql_id values.

The final 8 bytes of the full_hash_value are converted into two integer values

Given the full_hash_value for our working query:
51CAF1AB A0366BFB 4568F7FE 07E34BF4

The 3rd and 4th quartets are first converted to integers:

```sql
SQL# select to_number('4568F7FE','XXXXXXXX') n1 from dual;

        N1
----------
1164507134


SQL# select to_number('07E34BF4','XXXXXXXX') n2 from dual;

        N2
----------
 132336628

```

A hash value is generated when N1 is multiplied by 4Gig and N2 added to the result:

```sql
SQL# select ( 1164507134 * 4*power(2,30) + 132336628 ) from dual;

(1164507134*4*POWER(2,30)+132336628)
------------------------------------
                 5001520056621026292

```

Then a loop is iterated 13 times, successively using the remainder of hv/32 as a pointer in to the alphapbet, and then dividing the hash by 32.

Here it is in PL/SQL:

``sql
function md5_to_sqlid(md5 in raw) return varchar2
is
   type map_type is varray(32) of varchar2(1);
   sqlid_map  map_type := 
      map_type('0', '1', '2', '3', '4', '5', '6', '7',
               '8', '9', 'a', 'b', 'c', 'd', 'f', 'g',
               'h', 'j', 'k', 'm', 'n', 'p', 'q', 'r',
               's', 't', 'u', 'v', 'w', 'x', 'y', 'z');

   hash  number;
   sqlid varchar2(13);
begin
   hash := unsigned_integer(utl_raw.substr(md5, 9, 4)) * 4294967296 +
     unsigned_integer(utl_raw.substr(md5, 13, 4));

   for i in 1..13 loop
      sqlid := sqlid_map(mod(hash,32)+1) || sqlid;
      hash  := trunc(hash/32);
   end loop;
   return sqlid;
end;
```

And as a Bash function:

```bash
md5_to_sqlid () {
   local md5="$1"

   declare -a sqlid_map=(
       [0]='0'  [1]='1'  [2]='2'  [3]='3'  [4]='4'  [5]='5'  [6]='6'  [7]='7'
       [8]='8'  [9]='9' [10]='a' [11]='b' [12]='c' [13]='d' [14]='f' [15]='g'
      [16]='h' [17]='j' [18]='k' [19]='m' [20]='n' [21]='p' [22]='q' [23]='r'
      [24]='s' [25]='t' [26]='u' [27]='v' [28]='w' [29]='x' [30]='y' [31]='z'
   );

   declare h1=${md5:16:8}
   declare h2=${md5:24:8}

   declare hn1=$(endian_4 $h1)
   declare hn2=$(endian_4 $h2)

   declare n1=$(hex_to_num $hn1)
   declare n2=$(hex_to_num $hn2)

   declare hv
   (( hv = n1 * 4294967296 + n2 ))

   declare sql_id

   for i in {1..13}
   do
      (( r = ( hv % 32 ) +1 ))
      sql_id=${sqlid_map[r-1]}${sql_id}
      (( hv = hv/32 ))
   done

   echo $sql_id
}

```

Results using the Bash function md5_to_sqlid:

```text
$  md5_to_sqlid ABF1CA51FB6B36A0FEF76845F44BE307
4au7rzs3y6kzn
```

This is the correct sql_id for our test query.


## Incorrect Results

When scanning all of the SQL in test database, these functions fail to generate the correct FHV in in 8-10% of the SQL statements.

For those that fail, success can sometimes be achieved by appending an additional chr(0) to the end of the SQL.

This statement for instance, gets the correct full_hash_value (and sql_id and hash_value) only when there are two chr(0) appended to the end of the SQL text:

```sql
SELECT ATTRIBUTE,SCOPE,NUMERIC_VALUE,CHAR_VALUE,DATE_VALUE FROM SYSTEM.PRODUCT_PRIVS WHERE (UPPER('SQL*Plus') LIKE UPPER(PRODUCT)) AND (USER LIKE USERID)
```

I saw one case of 3 chr(0) being required, though I failed to record which SQL that was.

The following is an Oracle note with some information on flags passed to dbms\_utility.get\_sql\_hash in the form of characters appended to the SQL text

  `Querying V$Access Contents On Latch: Library Cache (Doc ID 757280.1)`

While that note applies to getting hash values for objects other than SQL statements, the information still applies.

In it the note shows how different characters are used to indicate to the hash generation routines what kind of object is being considered.

As implied by the note, there is internal logic in the packaged Hash algorithms that is not made available outside of Oracle Corp. (at least I have not found it)

So it would seem there are additional 'flags' that are appended to SQL in some cases.

If I can find out what those cases are, I will update this document.

A caveat is in order:  the SQL being tested so far is all SQL used internally by the Oracle database. When testing only application SQL, these hash value differences may not occur.

Again, I will update this document if I learn that is the case.


## Files

### dbms_crypto-hash.sql

Demo of using dbms_crypto.hash - see [dbms_crypto-hash.sql](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/dbms_crypto-hash.sql)

### dbms_utility-get_sql_hash.sql

Demo of using dbms_utility.get_sql_hash [dbms_utility-get_sql_hash.sql](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/dbms_utility-get_sql_hash.sql)

### gen-sql-full-hash-demo.sql

The [gen-sql-full-hash-demo.sql](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/gen-sql-full-hash-demo.sql) script will generate the FHV and other values for all statements in v$sql, and compare the generated values to the real values.

See also [sql-gen-full-hash-demo.sql](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/sql-gen-full-hash-demo.sql)

### gen-sql-full-hash-value.sql

Another FHV generation script [gen-sql-full-hash-value.sql](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/gen-sql-full-hash-value.sql)

### gen-sql-hash-hdr.sql

A package using some of the methods shown in this document:  
[gen-sql-hash-hdr.sql](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/gen-sql-hash-hdr.sql)
[gen-sql-hash-body.sql](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/gen-sql-hash-body.sql)

Demo of package: [gen-sql-hash-package-demo.sql](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/gen-sql-hash-package-demo.sql)

### hexdump-sql.sql

Use [hexdump](https://github.com/jkstill/hexadecimal/tree/master/hexdump) to dump SQL as a canonical hex dump.

### hash-gen-demos/dump-sql.pl

A Perl script that will dump all SQL to files

Use with Oracle installed Perl:

```text
$ORACLE_HOME/perl/bin/perl dump-sql.pl --help
```

### hash-gen-demos/gen-fhv.sh

Generate the FHV and other values from a file containing a SQL statement saved by `dump-sql.pl`: [gen-fhv.sh](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/hash-gen-demos/gen-fhv.sh)

### hash-gen-demos/gen-all-fhv.sh

Run `gen-fhv.sh` for all SQL saved in files by `dump-sql.pl`: [gen-all-fhv.sh](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/hash-gen-demos/gen-all-fhv.sh)

### hash-gen-demos/sqlid-alphabet.sql

As show previously, generate sql_id from SQL text: [sqlid-alphabet.sql](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/hash-gen-demos/sqlid-alphabet.sql)

### hash-gen-demos/sqlid-funcs.sh

The Bash functions in a function-only file that may be sourced: [sqlid-funcs.sh](https://github.com/jkstill/oracle-demos/blob/master/sql-hash-value/hash-gen-demos/sqlid-funcs.sh)

