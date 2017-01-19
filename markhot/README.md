
<h2>dbms_shared_pool.markhot example</h2>


The dbms_shared_pool.markhot procedure can be used to allow multiple copies of a cursor object to exist. 
This has been proven to work effectively with evidence following.
Please refer to this Oracle Support Note: How to Use ASH Report to Identify Hot Object for 
Dbms_shared_pool.markhot (Doc ID 2194448.1)

Tests were performance an unpatched single instance of 12.1.0.2.

The cursor: pin S wait on X wait event can be induced by using a complex SQL statement and causing the optimizer to consider more plans that it normally would.

Note: all scripts and trace files are available in a zip file markhot-test.zip.


<h3>Create the test table</h3>

Note: No rows are required for this to work.

@@create.sql

<h3>Run the test script</h3>

This script is run simultaneously in 2 sqlplus sessions. About 20-30 seconds are required to parse this query in the test database.

Uncomment some of the tables in the from clause if it runs too fast in your environment.
(This will change the SQL_ID)

Alternatively increase the value for _optimizer_search_limit

@@test.sql

<h3>Initial test</h3>

Initial tests show one of the sessions waiting on cursor: pin S wait on X for most of the session time.
Directory: trace-markhot-off-2

<pre>

CALL-NAME                     DURATION       %  CALLS       MEAN        MIN        MAX
---------------------------  ---------  ------  -----  ---------  ---------  ---------
cursor: pin S wait on X      21.411263   98.9%      1  21.411263  21.411263  21.411263
PARSE                         0.243000    1.1%      2   0.121500   0.000000   0.243000
EXEC                          0.001000    0.0%      2   0.000500   0.000000   0.001000
SQL*Net message from client   0.000931    0.0%      2   0.000465   0.000334   0.000597
SQL*Net message to client     0.000003    0.0%      2   0.000002   0.000001   0.000002
CLOSE                         0.000000    0.0%      2   0.000000   0.000000   0.000000
FETCH                         0.000000    0.0%      1   0.000000   0.000000   0.000000
---------------------------  ---------  ------  -----  ---------  ---------  ---------
TOTAL (7)                    21.656197  100.0%     12   1.804683   0.000000  21.411263

</pre>

<h3>Second Test</h3>

The test was again run without making any changes; it is expected that the cursor wait will not appear for either session.

Directory: trace-markhot-off-2b
This is the total time for both sessions combined

<pre>

CALL-NAME                    DURATION       %  CALLS      MEAN       MIN       MAX
---------------------------  --------  ------  -----  --------  --------  --------
SQL*Net message from client  0.001257   55.6%      4  0.000314  0.000160  0.000533
EXEC                         0.001000   44.3%      4  0.000250  0.000000  0.001000
SQL*Net message to client    0.000002    0.1%      4  0.000000  0.000000  0.000001
CLOSE                        0.000000    0.0%      4  0.000000  0.000000  0.000000
PARSE                        0.000000    0.0%      4  0.000000  0.000000  0.000000
FETCH                        0.000000    0.0%      2  0.000000  0.000000  0.000000
---------------------------  --------  ------  -----  --------  --------  --------
TOTAL (6)                    0.002259  100.0%     22  0.000103  0.000000  0.001000

</pre>


<h3>Third Test</h3>

The cursor was purged from the shared pool, and the tests rerun. It is expected the cursor pin wait will return, and it does.

Directory: trace-markhot-off-2c

<pre>

CALL-NAME                     DURATION       %  CALLS       MEAN        MIN        MAX
---------------------------  ---------  ------  -----  ---------  ---------  ---------
cursor: pin S wait on X      20.629070   98.9%      1  20.629070  20.629070  20.629070
PARSE                         0.232000    1.1%      2   0.116000   0.000000   0.232000
SQL*Net message from client   0.000766    0.0%      2   0.000383   0.000165   0.000601
SQL*Net message to client     0.000002    0.0%      2   0.000001   0.000001   0.000001
CLOSE                         0.000000    0.0%      2   0.000000   0.000000   0.000000
EXEC                          0.000000    0.0%      2   0.000000   0.000000   0.000000
FETCH                         0.000000    0.0%      1   0.000000   0.000000   0.000000
---------------------------  ---------  ------  -----  ---------  ---------  ---------
TOTAL (7)                    20.861838  100.0%     12   1.738486   0.000000  20.629070

</pre>

Now that a baseline is established, testing with the markhot procedure begins

<h3>Markhot Use Enabled But Not Yet Implemented</h3>

The static parameter _kgl_hot_object_copies must be set to allow the use of dbms_shared_pool.markhot. 

Doing so requires a database restart.

<pre>   alter system set "_kgl_hot_object_copies"=2 scope=spfile;</pre>

The value of ‘2’ indicates that 2 copies of the cursor may be made in the shared pool. This will allow each of 
the 2 test sessions to have a copy of the cursor when markhot is employed. At this point the tests appear as expected; the cursor: pin S wait on X wait appears as it did in the previous 
tests.

Directory: trace-markhot-enabled-not-yet-marked

<pre>

CALL-NAME                     DURATION       %  CALLS       MEAN        MIN        MAX
---------------------------  ---------  ------  -----  ---------  ---------  ---------
cursor: pin S wait on X      20.278712   99.0%      1  20.278712  20.278712  20.278712
PARSE                         0.205000    1.0%      2   0.102500   0.000000   0.205000
EXEC                          0.001000    0.0%      2   0.000500   0.000000   0.001000
SQL*Net message from client   0.000748    0.0%      2   0.000374   0.000181   0.000567
SQL*Net message to client     0.000003    0.0%      2   0.000002   0.000001   0.000002
CLOSE                         0.000000    0.0%      2   0.000000   0.000000   0.000000
FETCH                         0.000000    0.0%      1   0.000000   0.000000   0.000000
---------------------------  ---------  ------  -----  ---------  ---------  ---------
TOTAL (7)                    20.485463  100.0%     12   1.707122   0.000000  20.278712

</pre>


<h3>Markhot Used</h3>

Following the instructions from Oracle Note 2194448.1 the SQL_ID for the test was marked as 'hot' with dbms_shared_pool:

The following scripts were used, with the output shown following

 get-kglnahsv.sql
 markhot.sql

<pre>

SQL> select kglnahsv from v$sql, x$kglob
where kglhdadr=address
and sql_id = ‘8buc8vvg6765r’
/
KGLNAHSV
--------------------------------a6200685bcab063585e988dede6398b7

SQL> begin
dbms_shared_pool.markhot('a6200685bcab063585e988dede6398b7', 0);
end;
/

</pre>

Please remember that if the SQL in test.sql is altered, the sql_id and hash values will change.

Next the same tests were run in 2 simultaneous sessions:
Directory: trace-markhot-enabled-marked-hot

<pre>

CALL-NAME                     DURATION       %  CALLS       MEAN       MIN        MAX
---------------------------  ---------  ------  -----  ---------  --------  ---------
PARSE                        42.933000  100.0%      4  10.733250  0.000000  21.629000
SQL*Net message from client   0.002207    0.0%      4   0.000552  0.000189   0.001196
db file sequential read       0.000122    0.0%      5   0.000024  0.000016   0.000048
SQL*Net message to client     0.000005    0.0%      4   0.000001  0.000000   0.000002
CLOSE                         0.000000    0.0%      4   0.000000  0.000000   0.000000
EXEC                          0.000000    0.0%      4   0.000000  0.000000   0.000000
FETCH                         0.000000    0.0%      2   0.000000  0.000000   0.000000
---------------------------  ---------  ------  -----  ---------  --------  ---------
TOTAL (7)                    42.935334  100.0%     27   1.590198  0.000000  21.629000

</pre>

Note that the parse total for the 2 sessions is 43 seconds; each session was required to fully parse the 
statement. This is to be expected.

The benefit to using markhot is realized when multiple sessions are attempting to all parse the same SQL statement at 
the same time. Combined with the long parse times being seen as a result of dynamic statistics, some SQL 
statements are requiring several minutes to parse. Even without the dynamic statistics, the event cursor: pin S 
wait on X is going to occur due to many sessions attempting to parse simultaneously.

<h3>Unmark hot and retest</h3>

Using dbms_shared_pool.unmarkhot has the side effect of purging the cursor from the shared spool. The 
intent of this test was to see if the cursor wait reappeared.

<h4>Results on unpatched 12.1.0.2 single instance</h4>

While the event did reappear, each session would consistently crash with an ORA-7445. As this is a 
completely unpatched version of the database, it is not surprising that some bugs would appear. A search on 
the Oracle Support site did reveal a number of bugs related to the markhot procedures; at this time I do not 
what patches may be related to this. The issue can be re-examined as necessary

<h4>Results on patched 12.1.0.2 Two node RAC</h4>

Using dbms_shared_pool.unmarkhot on this database worked as expected without error.

One session waited on 'cursor: pin S wait on X' as expected




