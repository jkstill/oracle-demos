

drop database link oravm01;

create database link oravm01 connect to jkstill identified by grok using '(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=oravm01)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=oravm.jks.com)))'
/

select instance_name from v$instance@oravm01;

