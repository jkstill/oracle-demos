
set num 20
col cpu_time format a20
col name format a50

select signature, name, plan_hash_value, cpu_time from DBA_SQL_QUARANTINE
/
