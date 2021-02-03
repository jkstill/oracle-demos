select 
radix.to_bin(1048576  )
,radix.to_bin(floor(1048576 / power(2,10)) )
, floor(1048576 / power(2,10)) 
from dual
/
