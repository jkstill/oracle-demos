
col p1text format a10
col p2text format a15
col p3text format a15

set linesize 200

select
	sid, event
	, p1
	, chr(to_number(substr(TRIM(to_char(p1,'XXXXXXXXXXXXXXXX')),1,2),'XXXXXXXX'))
	|| chr(to_number(substr(TRIM(to_char(p1,'XXXXXXXXXXXXXXXX')),3,2),'XXXXXXXX')) type
	, to_number(substr(TRIM(to_char(p1,'XXXXXXXXXXXXXXXX')),5),'XXXXXXXX') enq_mode
from v$session
where blocking_session is not null
/
