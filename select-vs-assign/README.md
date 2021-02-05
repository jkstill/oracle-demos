Select vs Assign
================

It is not unusual to see PL/SQL that contains `select columns into variables from some_table`.

This is normal and expected when the data you need is in a table.

However, many years ago, Oracle provided a workaround for using SELECT statements in somewhat unorthodox way via the DUAL table.

Some examples:

```sql
select sysdate into vDate from dual

select user into vUser from dual

select sys_context('userenv','sid') into vSID from dual;
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

The same assignment can be performed directly:

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

Additionally, the scripts will be run with any monitoring, just so we can see the timing data.

Timing will be just be via `set timing on` in SQLPlus.

If you are unfamiliar with perf, this is a good place to start: [perf](http://www.brendangregg.com/perf.html)

All scripts are shown in their entirety at the end of this article.


## Timings

Before doing any kind of tracing, I will first run the test scripts to get timing information.

First I will run `select.sql`, and then `assign.sql`.

Each script will make 1M variable assignments.


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

Assigning `sysdate into vDate` 1M times took 7.99 seconds.

### assign.sql

```text
SQL# @assign

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

Now, let's dig a little bit deeper and get a better understanding of why there is such a large difference between the two methods of assigning a value to a variable.

## Testing with Perf

We can use perf to count the operations performed by the server.

The `record.sh` script is used to start the recording on the server.

### Testing Method

This is a fairly simple manual testing method.

Each of the SQL scripts will pause until ENTER is pressed.

While the SQL script is paused, I switch to the ssh session where I am logged into the database server as root.

Then I started the perf recording via `./record.sh PID`

Switching back to the SQLPlus session, I press ENTER.

Then I switch back to the server, and press CTL-C when the SQLPlus job is done.

Though somewhat crude, this method is sufficient for these tests.

Each of the tests was performed in this way, resulting in two files

- perf.data.assign
- perf.data.select

These files were renamed from the default `perf.data` following each test.

In the previous tests you may have noticed that the SPID was reported.
This refers to the server PID for the Oracle process started in behalf of the SQLPlus session.
It is this PID that is used with the `record.sh` script.

eg. `./record.sh 13280`

The same SQL scripts were run while recording each with perf.

### perf report

Now to create a report from each file.

The following command was used to create a nice execution tree of each data file, along with counts for each function called.

```text
perf report --stdio -g count -i perf.data.select
```

The output is fairly interesting, but we will not be delving into it today.

What is most interesting at this time is the number of operations performed, expressed as counters in perf.

We aren't looking at timing, just how much work had to be done on the server for each test script.

For that, we just need one line from each file:

```text
$ grep 'Event count'  perf.rpt.*
 perf.rpt.assign:# Event count (approx.): 223223223
 perf.rpt.select:# Event count (approx.): 7292292285
```

Well, that is interesting. The number of calls when running the `select.sql` script 32x that of the `assign.sql` script.

## Testing with Oracle Trace

There are a number of methods to start a trace on an Oracle Session.

Here I will be using the old standby, `alter session set events '10046 trace name context forever, level 12'`, simply because I have a script for it, and the name is easy to remember.

The same two test SQL scripts were again run, but this time by first setting the `tracefile_identifier` and enabling the trace.

### select.sql

```text
alter session set tracefile_identifier = 'SELECT';
select value from v$diag where name = 'Default Trace File';
@@10046
@@select
exit
```

### assign.sql

```text
alter session set tracefile_identifier = 'ASSIGN';
select value from v$diag where name = 'Default Trace File';
@@10046
@@assign
exit
```

Then the tracefiles were copied from the server.


### Analisys

We can learn a bit just by checking the sizes of the files:

```text
$  wc cdb1_ora*.trc
  3000405   6001742 256119114 cdb1_ora_5689_SELECT.trc
      159       850      9088 cdb1_ora_6414_ASSIGN.trc
  3000564   6002592 256128202 total
```

There is striking disparity in the size of those files.

The overhead of using Oracle Trace caused the execution time of `select.sql` to balloon from 8 seconds to 55 seconds.

Here is a simple profile of each trace file:

```text
$ ./profiler-2.pl cdb1_ora_5689_SELECT.trc
Response Time Component                    Duration     Pct    # Calls      Dur/Call
----------------------------------------  ---------  ------  ---------  ------------
CPU service                                  45.13s   80.9%         12     3.761055s
SQL*Net message from client                   6.12s   11.0%          7     0.874465s
unaccounted-for                               4.52s    8.1%          1     4.515813s
library cache lock                            0.00s    0.0%          1     0.000958s
library cache pin                             0.00s    0.0%          1     0.000514s
PGA memory operation                          0.00s    0.0%         29     0.000009s
SQL*Net message to client                     0.00s    0.0%          7     0.000001s
----------------------------------------  ---------  ------  ---------  ------------
Total response time                          55.77s  100.0%


$ ./profiler-2.pl cdb1_ora_6414_ASSIGN.trc
Response Time Component                    Duration     Pct    # Calls      Dur/Call
----------------------------------------  ---------  ------  ---------  ------------
SQL*Net message from client                   6.63s   95.5%          7     0.946822s
CPU service                                   0.31s    4.4%         12     0.025454s
unaccounted-for                               0.01s    0.1%          1     0.009777s
PGA memory operation                          0.00s    0.0%          2     0.000009s
SQL*Net message to client                     0.00s    0.0%          7     0.000001s
----------------------------------------  ---------  ------  ---------  ------------
Total response time                           6.94s  100.0%
```

It would seem the results are a bit skewed by the overhead of the trace, as there are 45 seconds of CPU used.
(recall that without tracing, the script took 8 seconds)

Using standard linux tools, we can get a better idea of why the `select.sql` takes so much more time than `assign.sql`.

_select.sql trace_

```text
  awk '{ print $1 }' cdb1_ora_5689_SELECT.trc | sort | uniq -c | sort -n | tail -20
      3 select
      3 toid
      3 value=###
      3 value=4294951004
      5 =====================
      5 END
      5 PARSING
      7 PARSE
     11 kxsbbbfp=7f7826769da0
     12 STAT
     14 BINDS
     14 Bind#0
     14 oacdty=02
     14 oacflg=00
     45 WAIT
     58 ***
     67
1000013 FETCH
1000016 EXEC
1000021 CLOSE
```

_assign.sql trace_

```text
  awk '{ print $1 }' cdb1_ora_6414_ASSIGN.trc | sort | uniq -c | sort -n | tail -20
      3 BINDS
      3 Bind#0
      3 Bind#1
      3 Dump
      3 Dumping
      3 END
      3 PARSING
      3 oacdty=02
      3 oacdty=123
      3 oacflg=00
      3 oacflg=01
      3 toid
      3 value=###
      5 EXEC
      5 PARSE
      9
      9 STAT
     10 CLOSE
     11 ***
     16 WAIT
```

The last three lines of the report for `select.sql` tell the story; when assigning variable via `select into from dual`, Oracle had to create, fetch and close a cursor 1M times.

That overhead can be avoided simply by assigning variables directly, as seen in `assign.sql`.

Any blog that uses perf for analysis would be incomplete without the requisite Flame Graphs

### Flame Graph for select.sql

What is of interest in these flame graphs is the amount of work being done once the script enters the plsql_run section.

The select.sql script has quite a bit of code being executed; not only is there a large stack of code being executed, it is very wide, which in in a flame graph indicates a lot of work being performed.

[Flame Graph for select.sql](https://github.com/jkstill/oracle-demos/blob/master/select-vs-assign/perf-select.svg)

### Flame Graph for assign.sql

Now take a look the the flame graph for assign.sql.  There is much less above the plsql_run section. Not only is the stack shorter, it is much narrower, and therefore faster.

[Flame Graph for assign.sql](https://github.com/jkstill/oracle-demos/blob/master/select-vs-assign/perf-assign.svg)

## Conclusion

It is good to periodically test your assumptions.

You probably would not notice the difference in singleton events that happen too quickly for a human to perceive the difference in timing.

But when scaled up, such as I have done here, the differences are easy to see.

Will using a direct assignment make a noticable difference in a PL/SQL program that does it only once?  Probably not.

But what if that PL/SQL program is called frequently?

What if there are several PL/SQL programs doing this?  Maybe some of them doing so in a loop?

Not only would the difference in performance be discernable, but extra resources would be consumed, which would not available for other processes.

The next time you are writing some PL/SQL, be sure to look at it with a critical eye toward the impact it will have on system performance.


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








