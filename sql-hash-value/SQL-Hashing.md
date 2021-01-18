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
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
  2  	hash_value number;
  3  	v_sql varchar2(100);
  4  	r_full_hash_value raw(128);
  5  	raw_pre10_hash number;
  6  begin
  7  	v_sql := 'select dummy from dual';
  9  		name => v_sql || chr(0)
 10  		, hash => r_full_hash_value
 11  		, pre10ihash => raw_pre10_hash
 12  	);
 13  	dbms_output.put_line('hash_value: ' || to_char(hash_value));
 14  	dbms_output.put_line('full_hash_value: ' || r_full_hash_value);
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
  2  	hash_value number;
  3  	v_sql varchar2(100);
  4  	r_full_hash_value raw(16);
  5  	corrected_full_hash_value raw(16);
  6  	raw_pre10_hash number;
  7  begin
  8  	v_sql := 'select dummy from dual';
  9  	hash_value := dbms_utility.get_sql_hash(
 10  		name => v_sql || chr(0)
 11  		, hash => r_full_hash_value
 12  		, pre10ihash => raw_pre10_hash
 13  	);
 14  	dbms_output.put_line('hash_value: ' || to_char(hash_value));
 15  	dbms_output.put_line('full_hash_value: ' || r_full_hash_value);
 16  	corrected_full_hash_value :=
 17  		utl_raw.reverse(utl_raw.substr(r_full_hash_value,1,4)) ||
 18  		utl_raw.reverse(utl_raw.substr(r_full_hash_value,5,4)) ||
 19  		utl_raw.reverse(utl_raw.substr(r_full_hash_value,9,4)) ||
 20  		utl_raw.reverse(utl_raw.substr(r_full_hash_value,13));
 21  	dbms_output.put_line('corrected_full_hash_value: ' || corrected_full_hash_value);
 22* end;
 23  /
hash_value: 132336628
full_hash_value: ABF1CA51FB6B36A0FEF76845F44BE307
corrected_full_hash_value: 51CAF1ABA0366BFB4568F7FE07E34BF4
```

Now it the generated full_hash_value is correct.

     Real Full Hash Value:  51CAF1AB A0366BFB4 568F7FE 07E34BF4
corrected_full_hash_value:  51CAF1AB A0366BFB4 568F7FE 07E34BF4

These tests were performed on 64 bit Linux running on Intel processor.

The tests may work differently on big-endian platforms, in which case the dbms_utility.get_endianness function would be useful.


### dbms_crypto.hash

The dbms_crypto.hash function can return a hash without the varchar2 limitations found in dbms_utility.get_sql_hash.

See dbms_crypto-hash.sql

```text
  1  declare
  2  	md5hash raw(16);
  3  	full_hash_value raw(16);
  4  	c_sql clob;
  5  begin
  6  	c_sql := 'select dummy from dual';
  7
  8  	md5hash :=
  9  		rawtohex(
 10  			dbms_crypto.hash(
 11  				src =>c_sql||chr(0),
 12  				typ => dbms_crypto.HASH_MD5
 13  			)
 14  		);
 15
 16  	dbms_output.put_line('md5hash: ' || md5hash);
 17
 18  	full_hash_value :=
 19  		utl_raw.reverse(utl_raw.substr(md5hash,1,4)) ||
 20  		utl_raw.reverse(utl_raw.substr(md5hash,5,4)) ||
 21  		utl_raw.reverse(utl_raw.substr(md5hash,9,4)) ||
 22  		utl_raw.reverse(utl_raw.substr(md5hash,13));
 23
 24  	dbms_output.put_line('full_hash_value: ' || full_hash_value);
 25
 26* end;
JKSTILL@ora192rac-scan/pdb1.jks.com > /
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

The gen-fhv-demo.sh script:

```bash
#!/usr/bin/env bash

hex_to_num () {
	local hexnum="$1"
	#echo "hexnum: $hexnum"
	printf "%d" $((16#$hexnum))
}

# oracle is using the last 4 bytes of the full_hash_value(hex) to generate the hash_value (number)
fhv_to_hash_value () {
	local fhv="$1"
	hex_to_num ${fhv:24:8}
}

# expecting 8 character string - 4 bytes hex
endian_4 () {
	local hexstr="$1"

	local whash="$1"

	declare -a md5parts

	whash[0]=${hexstr:0:2}
	whash[1]=${hexstr:2:2}
	whash[2]=${hexstr:4:2}
	whash[3]=${hexstr:6:2}

	declare new_hex

	for i in {3..0}
	do
		declare tmp=${hexstr[$i]}
		#echo "i: $i  $tmp"
		new_hex="$new_hex"${whash[$i]}
	done

	echo $new_hex
}

md5_to_fhv () {
	local md5="$1"

	declare -a md5parts

	md5parts[0]=${md5:0:8}
	md5parts[1]=${md5:8:8}
	md5parts[2]=${md5:16:8}
	md5parts[3]=${md5:24:8}

	declare new_fhv

	#echo "md5_to_fhv: $md5"

	for i in {0..3}
	do
		declare tmp=${md5parts[$i]}
		#echo "i: $i  $tmp"
		for j in {3..0}
		do
			new_fhv="$new_fhv"${tmp:((j*2)):2}
		done
	done

	echo $new_fhv

}

md5_to_sqlid () {
	local md5="$1"

	declare -a sqlid_map=(
		[0]='0' [1]='1' [2]='2' [3]='3' [4]='4' [5]='5' [6]='6' [7]='7'
		[8]='8' [9]='9' [10]='a' [11]='b' [12]='c' [13]='d' [14]='f' [15]='g'
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


##########
## main ##
##########

# get the md5 from a file

declare sqlfile=${1:?'Please specify a file'}

[ -r "$sqlfile" ] || {

	echo
	echo cannot open "$sqlfile"
	echo
	exit 1

}

declare md5=$(md5sum "$sqlfile" | awk '{ print $1 }')

echo "    md5: $md5"
declare gen_fhv=$(md5_to_fhv $md5)

echo "       generated fhv: $gen_fhv"

# oracle is using the last 4 bytes of the full_hash_value(hex) to generate the hash_value (number)
declare hash_value=$(fhv_to_hash_value $gen_fhv)
echo "generated hash_value: $hash_value"

declare sql_id=$(md5_to_sqlid $md5)
echo "    generated sql_id: $sql_id"

```

## The SQL_ID alphabet

The values used for the sql_id may be found by finding all distinct values of letters that occur in the string




















