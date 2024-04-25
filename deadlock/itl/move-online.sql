
def newtbs='EVS';
set verify off

set echo on

@10046

alter index itl_wait_u_idx rebuild online tablespace &newtbs initrans 10;

alter table itl_wait move online tablespace &newtbs initrans 10;

@10046_off

set echo off

@tracefile

