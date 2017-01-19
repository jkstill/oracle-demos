
set term off

select /*+ parallel(4) */ *
from ctest t1
, ctest t2
/

set term on

