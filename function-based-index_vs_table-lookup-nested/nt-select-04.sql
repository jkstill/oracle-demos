
/* 
SQL# desc func_test_prize
 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 COMP_ID                                            NUMBER
 COMP_NAME                                          VARCHAR2(20)
 PAY_ID                                             NUMBER
 CREDIT_ID                                          NUMBER
 PERIOD_END_DATE                                    DATE
 TRANS_TYPE                                         VARCHAR2(1)
 STATUS                                             VARCHAR2(10)
 PRIZE_CODES                                        PRIZE_CODE_NT
 C1                                                 VARCHAR2(20)
 C2                                                 VARCHAR2(20)
 C3                                                 VARCHAR2(20)

SQL#
SQL# desc PRIZE_CODE_NT
 PRIZE_CODE_NT TABLE OF PRIZE_CODE_OBJ_TYP
 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
  CODE_NUM                                           NUMBER(2)

*/



set timing on

select count(*) from (
select /*+ all_rows */
	f.comp_id
	, f.pay_id
	, f.credit_id
	-- the column in the PRIZE_CODE_OBJ_TYP
	, f.prize_codes
from func_test_prize f
where prize_code_sum(f.prize_codes) = 42
)
/

