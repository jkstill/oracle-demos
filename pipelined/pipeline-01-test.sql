SELECT * FROM TABLE (
  pipeline_01.prow_test (
    CURSOR (SELECT * FROM pipeline_test)
  )
)
/
