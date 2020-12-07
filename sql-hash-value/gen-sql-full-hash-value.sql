
/*

use dbms_utility.get_sql_hash() to calculate the full_hash_value from the SQL text

This is not infallible, as about 1% of sql tested get an incorrect full_hash_value

If Oracle is using dbms_utility.get_sql_hash internally and/or ICD_GETSQLHASH (C lib)
then there are SQL statements that are not being hashed correctly.

Also, it seems that ICD_GETSQLHASH is not what is being used to generate the value for X$KGLOB.KGLNAHSV

*/

create or replace function gen_sql_full_hash_value ( sql_id_in varchar2 ) return varchar2
is

	/*
		Jared Still - 2020-12-06
		jkstill@gmail.com
	*/

	c_sql clob;
	my_dummy number;
	n_lob_len number;

	full_hash_value varchar2(32);
	md5hash varchar2(32);
	raw_hash raw(128);
	n_pre10i_hash number;

	max_sql_len CONSTANT integer := 32767;

	function little_endian ( hash_str varchar2 ) return varchar2
	is
		octet varchar2(8);
		le_str varchar2(32);  -- le: little endian
		v_byte varchar2(2);
	begin
		le_str := '';
		-- assumes 32 characters
		for i in 0..3
		loop
			octet := substr(hash_str,i*8+1,8);
			--dbms_output.put_line('octet: ' || octet);
			for j in reverse 0..3
			loop
				v_byte := substr(octet,j*2+1,2);
				--dbms_output.put_line('v_byte: ' || v_byte);
				le_str := le_str || v_byte;
			end loop;
		end loop;
		return le_str;
	end;


begin

	full_hash_value := 'NA';

	-- get the sql
	with sqlsrc as (
		select sql_fulltext as sql_text
		-- even in 19c, v$sqlstats.sql_fulltext is truncated - ages old  bug
		--from v$sqlstats
		from v$sqlarea
		where sql_id = sql_id_in
		union all
		select sql_fulltext as sql_text
		from v$sql
		where sql_id = sql_id_in
		union all
		select sql_text
		from dba_hist_sqltext
		where sql_id = sql_id_in
	)
	select sql_text into c_sql
	from sqlsrc
	where rownum < 2;

	if c_sql = empty_clob() then
		return full_hash_value;
	end if;

	--n_lob_len := dbms_lob.getlength(c_sql);
	--dbms_output.put_line('  calc_hash.sql len: ' || n_lob_len);
	-- oracle uses the first 32767 bytes of the string to calculate the hash
	c_sql := dbms_lob.substr(c_sql,max_sql_len,1);

	-- using the built in utility, there are hash mismatches on the same sql as seen in other methods tried in prototypes
	-- internally get_sql_hash calls ICD_GETSQLHASH, which is in a C library
	-- apparently ICD_GETSQLHASH is not used to generate X$KGLOB.KGLNAHSV
	my_dummy := dbms_utility.get_sql_hash (
		name => c_sql||chr(0),
		hash => raw_hash,
		pre10ihash => n_pre10i_hash
	);

	md5hash := rawtohex(raw_hash);
	full_hash_value := lower(little_endian(md5hash));

	-- this would work, but so hard to read
	--full_hash_value := lower(little_endian(rawtohex(raw_hash)));

	return full_hash_value;

end;
/

show error function gen_sql_full_hash_value


