
drop database link oravm02;

create database link oravm02 connect to jkstill identified by grok using '(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=oravm02)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=oravm.jks.com)))'
/

select instance_name from v$instance@oravm02;

