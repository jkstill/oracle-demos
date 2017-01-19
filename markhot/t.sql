
alter session set "_optimizer_search_limit"=200;

col value format a80
select value from v$diag_info where name = 'Default Trace File';
@10046

select t1.*
from 
t t1
, t t2
, t t3
, t t4
, t t5
, t t6
, t t7
, t t8
, t t9
, t t10
/*, t t11
, t t12
, t t13
, t t14
, t t15
, t t16
, t t17
, t t18
, t t19
, t t20*/
/

@10046_off


