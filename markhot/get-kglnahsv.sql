select kglnahsv from v$sql, x$kglob
where kglhdadr=address
and sql_id = '&1'
/
