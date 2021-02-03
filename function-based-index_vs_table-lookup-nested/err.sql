
col text format a100
col err_line format a8

select 
	decode(line,&1,'==>> ' || line, line) err_line
	, text
from dba_source
where owner = 'JKSTILL'
and name = 'IS_PRIME'
and type = 'FUNCTION'
and line between &1 -5 and &1 + 5
order by name,type,line
/
