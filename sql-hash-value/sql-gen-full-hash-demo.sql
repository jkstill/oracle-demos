


-- format wrapped preserves leading whitespace
set serveroutput on size unlimited format wrapped

declare
	c_sql clob;
	md5_hash varchar2(32);
	sepline_len integer;
	sepline varchar2(100);
	i_sqlnum integer;
	my_dummy number;
	n_lob_len number;

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

	function calc_hash ( sql_id_in varchar2 ) return varchar2
	is
		full_hash_value varchar2(32);
		md5hash varchar2(32);
		raw_hash raw(128);
		n_pre10i_hash number;
		c_sql clob;
		n_sql_len number;

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
		c_sql := dbms_lob.substr(c_sql,32767,1);

		-- calculating our own hash value fails on some SQL statements
		-- several methods tried, all get the same wrong results on some SQL

		/*
		 thanks to Luca Canali for this sql to get MD5 - saved me some effort
		 dunno where the chr(0) might be documented.
		 https://externaltable.blogspot.com/2012/06/sql-signature-text-normalization-and.html

		 there is a clue to the appended character 0 in this doc:

		   Querying V$Access Contents On Latch: Library Cache (Doc ID 757280.1)

		 though it does not directly address SQL statements, it must be assumed that the chr() appended 
		 to the statement appears only in internal documentation
		*/	

		--select lower(rawtohex(utl_raw.cast_to_raw(dbms_obfuscation_toolkit.md5(input_string =>c_sql||chr(0))))) md5hash from dual
		-- use the newer dbms_crypto package instead of dbms_obfuscation_toolkit.md5 
		-- also no need to cast to raw, as it returns a RAW value


		/*
		-- converted to the more recent dbms_crypto.hash - already returns raw 
		-- so utl_raw.cast_to_raw not needed
		md5hash := 
			lower(
				rawtohex(
					dbms_crypto.hash(
						src =>c_sql||chr(0), 
						typ => dbms_crypto.HASH_MD5 
					)
				)
			);

		full_hash_value := little_endian(md5hash);
		*/

		-- using the built in utility, there are still hash mismatches on the same sql as seen in other methods
		-- internally this calls ICD_GETSQLHASH, which is in a C library
		--/*
		my_dummy := dbms_utility.get_sql_hash (
						name => c_sql||chr(0),
						hash => raw_hash,
						pre10ihash => n_pre10i_hash

		);

		md5hash := rawtohex(raw_hash);
		full_hash_value := lower(little_endian(md5hash));
		--*/

		return full_hash_value;

	end;


begin

	sepline_len := 60;
	sepline := rpad('=',sepline_len,'=');

	i_sqlnum := 0;

	for sqlrec in (
		with data as (
			select distinct sql_id, full_hash_value, sql_text, s.hash_value
			from v$sql s
			join v$db_object_cache o on o.hash_value = s.hash_value
				--and length(s.sql_text) <= 80
				--and rownum <= 5000
			order by sql_id
		)
		select sql_id, full_hash_value, sql_text, hash_value
		from data
		--where rownum <= 40
	)
	loop
		
		n_lob_len := dbms_lob.getlength(sqlrec.sql_text);
		dbms_output.put_line('  sql len: ' || n_lob_len);

		md5_hash := calc_hash(sqlrec.sql_id);
		i_sqlnum := i_sqlnum + 1;

		dbms_output.put_line('     sql#: ' || i_sqlnum);
		dbms_output.put_line('   sql_id: ' || sqlrec.sql_id);
		dbms_output.put_line('      sql: ' || sqlrec.sql_text);
		dbms_output.put_line('     hash: ' || gen_sql_hash.sql_id_to_hash(sqlrec.sql_id));
		dbms_output.put_line('full_hash: ' || sqlrec.full_hash_value);
		dbms_output.put_line('calc hash: ' || md5_hash);

		if sqlrec.full_hash_value != md5_hash then
			dbms_output.put_line(' ==>> MISMATCH ==<< ');
			--raise_application_error(-20000,'HASH Mismatch');
		end if;

		dbms_output.put_line(sepline);

	end loop;
end;
/


