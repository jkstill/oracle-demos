declare
	md5 raw(32);
	v_sqlid varchar2(13);

	n1 number;
	n2 number;

	function unsigned_integer(r in raw) return number as
		n number;
	begin
		n := utl_raw.cast_to_binary_integer(r, utl_raw.machine_endian);
		if (n < 0) then
			n := n + 4294967296;
		end if;
		return n;
	end;

-- create sql_id from md5 hash
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

	dbms_output.put_line('hash: ' || to_char(hash));

	for i in 1..13 loop
		sqlid := sqlid_map(mod(hash,32)+1) || sqlid;
		dbms_output.put_line('mod: ' || to_char(mod(hash,32)+1));
		hash  := trunc(hash/32);
		dbms_output.put_line('hash: ' || to_char(hash));
	end loop;
	return sqlid;
end;


begin
	md5 := dbms_crypto.hash(
		utl_raw.cast_to_raw(
			'delete from indpart$ where obj#=:1'||chr(0)
		)
		, 2
	);

	n1 := unsigned_integer(utl_raw.substr(md5, 9, 4));
	n2 := unsigned_integer(utl_raw.substr(md5, 13, 4));

	dbms_output.put_line('md5: ' || to_char(md5));
	dbms_output.put_line('md5 part 1: ' || utl_raw.substr(md5, 9, 4));
	dbms_output.put_line('md5 part 2: ' || utl_raw.substr(md5, 13, 4));
	dbms_output.put_line('n1: ' || to_char(n1));
	dbms_output.put_line('n2: ' || to_char(n2));

	--v_sqlid := gen_sql_hash.md5_to_sqlid(md5);
	v_sqlid := md5_to_sqlid(md5);

	dbms_output.put_line('sql_id:' || v_sqlid);


end;
/
