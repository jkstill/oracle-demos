
col company_name format a20
col period_end_date format a25
col c1 format a20
col c2 format a20
col c3 format a20

set linesize 200 trimspool on

set pagesize 100

insert into func_test
with companies as (
	select
		level company_id,
		dbms_random.string('L', 10) company_name
	from dual
	connect by level <= 100
),
payids as (
	select level pay_id
	from dual
	connect by level <= 5000
),
credit_ids as (
	select level credit_id
	from dual
	connect by level <= 5
)
select 
	c.company_id
	, c.company_name
	, p.pay_id
	, ci.credit_id
	,case trunc(dbms_random.value(1,5))
		when 1 then to_date('2020-03-31','yyyy-mm-dd')
		when 2 then to_date('2020-06-30','yyyy-mm-dd')
		when 3 then to_date('2020-09-30','yyyy-mm-dd')
		when 4 then to_date('2020-12-31','yyyy-mm-dd')
	end period_end_date
	, substr('ABCD',trunc(dbms_random.value(1,5)),1) trans_type
	, decode(mod(rownum,3),0,'ACTIVE',1,'INACTIVE',2,'PENDING') status
	, trunc(dbms_random.value(1,1000)) rval
	, dbms_random.string('L', 20) c1
	, dbms_random.string('L', 20) c2
	, dbms_random.string('L', 20) c3
from companies c
	,payids p
	, credit_ids ci
/


