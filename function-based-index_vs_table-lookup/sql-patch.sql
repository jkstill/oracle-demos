
-- sql-patch.sql
-- create a SQL patch to use the COMP_ID_IDX index

-- == create patch by sql_id ==

-- must be sysdba

var b_sql_id varchar2(13)

exec :b_sql_id := '00v5ashkdhw9n';


declare
   v_sql_id varchar2(13);
	profile_not_exist exception;
	pragma exception_init(profile_not_exist,-13833);
begin
	v_sql_id := :b_sql_id;
   dbms_sqldiag.drop_sql_patch(name => 'ft_' || v_sql_id);
exception
when profile_not_exist then
	null;
when others then
	raise;
end;
/

declare
   v_sql_id varchar2(13);
   v_patch_name varchar2(2000);
begin
	v_sql_id := :b_sql_id;
	-- if prior to 12.2
	-- dbms_sqldiag_internal._create_sql_patch
	v_patch_name :=  dbms_sqldiag.create_sql_patch(
		sql_id  => v_sql_id,
		hint_text => 'index(@"SEL$2" "FT" "COMP_ID_IDX")',
		--hint_text => 'gather_plan_statistics',
		name      => 'ft_' || v_sql_id
	);
	dbms_output.put_line('patch name: ' || v_patch_name);
end;
/

--== check patch status
select name, status from dba_sql_patches where name like 'ft_%';

