Select vs Assign
================

It is not unusual to see PL/SQL that contains `select columns into variables from some_table`.

This is normal and expected when the data you need is in a table.

However, many years ago, Oracle provided a workaround for using SELECT statements in somewhat unorthodox way via the DUAL table.

Some examples:

```sql
select sysdate from dual

select user from dual

select sys_context('userenv','sid') from dual;
```

While such usage can be useful at times, it is a bit of a performance hog.

In general, do not use `select .. into` when a direct variable assignment can be used.

Here is using `select into` to assign a date to a variable:

```sql
declare
  vDate date;
begin
  select sysdate into vDate from dual;
end;
/
```

The same assignment can be peformed directly:

```sql
declare
  vDate date;
begin
  vDate := sysdate;
end;
/
```

Do you think it makes any difference which method is used?

If you think they are equivalent, you may want to keep reading.


## Testing

Two SQL scripts will be used, `select.sql` and `assign.sql`.

Each script will assign sysdate to vDate 1M times in a loop.

Two different forms of monitoring will be used for the tests

- perf
- Oracle Trace

Additionaly, the scripts will be run with any monitoring, just so we can see the timing data.

Timing will be just be via `set timing on` in SQLPlus.

If you are unfamiliar with perf, this is a good place to start: [perf](http://www.brendangregg.com/perf.html)

All scripts are shown in their entirety at the end of this article.


## Timings

### select.sql

```text
SQL# @select

USERNAME                    SID SPID
-------------------- ---------- ------------------------
JKSTILL                      51 13280

1 row selected.


Testing speed of 'select into var'

Press ENTER when ready


Working...


PL/SQL procedure successfully completed.

Elapsed: 00:00:07.99
```

Assiging `sysdate into vDate` 1M times took 7.99 seconds.

### assign.sql

```text
QL# @assign

USERNAME                    SID SPID
-------------------- ---------- ------------------------
JKSTILL                      51 13280

1 row selected.

Elapsed: 00:00:00.02

Testing speed of 'var := something'

Press ENTER when ready


Working...


PL/SQL procedure successfully completed.

Elapsed: 00:00:00.33
```

Directly assigning via `vDate := sysdate` 1M times took significantly less time at 0.33 seconds.

It should be clear that `select from dual` should never be used when a direct variable assignment can be used.

Now, let's dig a little bit and get a better understanding of why there is such a large difference between the two methods of assigning a value to a variable.

## Testing with Perf

We can use perf to count the operations performaed by the server.

The `record.sh` script is used to start the recording.

### Testing Method

This is a fairly simple manual testing method.

Each of the SQL scripts will pause until ENTER is pressed.

While the SQL script is paused, I switch to the ssh session where I am logged into the database server as root.

Then I started the perf recording via `./record.sh PID`

Switching back to the SQLPlus session, I press ENTER.

Then I switch back to the server, and press CTL-C when the SQLPlus job is done.

This is somewhat crude, but sufficient for these tests.

Each of the tests was performed in this way, resulting in two files

- perf.data.assign
- perf.data.select

These files were renamed from the default `perf.data` following each test.

### perf report

Now to create a report from each file.

The following command was used to create a nice execution tree of each data file, along with counts for each function called.

```text
perf report --stdio -g count -i perf.data.select
```

The output is fairly interesting, but we will not be delving into it today.

What is most interesting at this time is the number of operations performed, expressed as counters in perf.

We aren't looking at timing, just how much work had to be done on the server for each test script.




## Testing with Oracle Trace

There are a number of methods to start a trace on an Oracle Session.

Here I will be using 


## Scripts

Following are all of the scripts used.

### get-curr-ospid.sql

```sql
-- get-curr-ospid.sql
--
-- get the server OS Pid for the current session
-- Jared Still jkstill@gmail.com still@pythian.com
col username format a20

select
	s.username,
	s.sid,
	p.spid
from v$session s, v$process p
where s.sid = sys_context('userenv','sid')
	and p.addr = s.paddr
order by username, sid
/
```

### select.sql

```sql

@get-curr-ospid

prompt
prompt Testing speed of 'select into var'
prompt
prompt Press ENTER when ready
prompt

accept dummy
prompt Working...
prompt

set timing on

declare
	vDate date;
begin
	for i in 1..1e6
	loop
		select sysdate into vDate from dual;
	end loop;
end;
/
```


### assign.sql

```sql

@get-curr-ospid

prompt
prompt Testing speed of 'var := something'
prompt
prompt Press ENTER when ready
prompt

accept dummy
prompt Working...
prompt

set timing on

declare
	vDate date;
begin
	for i in 1..1e6
	loop
		vDate := sysdate;
	end loop;
end;
/
```

### record.sh

```bash
#!/usr/bin/env bash

declare PID=$1

: ${PID:?Please supply PID}

[[ "$PID" =~ ^[0-9]+$ ]] || {
	echo
	echo $PID is not numeric
	echo 
	exit 1
}

echo Recording:

perf record -F 999 -T -g --timestamp-filename  -p $PID

```

### 10046.sql

```sql
-- level 4 is bind values
-- level 8 is waits
-- level 12 is both

--
-- see 10046_off.sql to end tracing

alter session set events '10046 trace name context forever, level 12';
--sys.dbms_system.set_ev(sid(n), serial(n), 10046, 8, '');

## 10046_off.sql
```

### 10046_off.sql

```sql
alter session set events '10046 trace name context off'
/
```

All files are found here on github: [select-vs-assign](https://github.com/jkstill/oracle-demos/select-vs-assign)








