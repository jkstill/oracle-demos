SELECT count(*) FROM TABLE (
  pipeline_01.prow_test2
)
/

SELECT count(*) FROM TABLE (
  pipeline_01.prow_test2('SYS')
)
/

SELECT count(*) FROM TABLE (
  pipeline_01.prow_test2('SCOTT')
)
/


