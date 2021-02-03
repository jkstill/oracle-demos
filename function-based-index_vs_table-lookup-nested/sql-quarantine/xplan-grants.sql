
def guser=scott

GRANT SELECT ON v_$session TO &guser;
GRANT SELECT ON v_$sql_plan_statistics_all TO &guser;
GRANT SELECT ON v_$sql_plan TO &guser;
GRANT SELECT ON v_$sql TO &guser;
