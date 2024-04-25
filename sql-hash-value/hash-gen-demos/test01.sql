SELECT "ROUTETO" AS "RouteTo" ,   "MASTERACCOUNTNUMBER" AS "MASTERACCOUNTNUMBER" ,   "CASEID" AS "CaseID" ,   "PXUPDATEOPERATOR" AS "pxUpdateOperator" ,   "CASEKEY" AS "CaseKey" ,   "CUSTOMERNAME" AS "CustomerName" ,   "PXCREATEDATETIME" AS "pxCreateDateTime" ,   "LASTUPDATED" AS "LastUpdated",  "PZINSKEY" as "pxInsHandle"  from MYQ_DATA.MYQ_SEARCH  WHERE  "PXOBJCLASS" = :1   AND (  ( "MASTERACCOUNTNUMBER" = :2  )   AND    "LASTUPDATED" >= :3     AND    "LASTUPDATED" <= :4   )