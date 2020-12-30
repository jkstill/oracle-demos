select * from TABLE(hexdump.hexdump(cursor(select sql_fulltext from v$sqlstats where sql_id = 'g4y6nw3tts7cc')))
/
