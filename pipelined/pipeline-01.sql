

-- create the table first with tables.sql




create or replace package pipeline_01
authid definer
is
	type refcur_t is ref cursor return pipeline_test%rowtype;

	type retrec_t is record (
		owner varchar2(128),
		table_name varchar2(128)
	);

	type retrec_set is table of retrec_t;

	function prow_test ( csr_in refcur_t ) return retrec_set pipelined;
	function prow_test2 ( owner_in varchar2 default null ) return retrec_set pipelined;


end;
/

show errors package pipeline_01

create or replace package body pipeline_01
is

   --=============================================================
	--== function prow_test
	--== 
	--== the cursor sent as an argument must match refcur_t
	--== used this way the cursor could have filters
   --=============================================================

	/*
		SELECT owner,table_name FROM TABLE (
  		pipeline_01.prow_test (
    		CURSOR (SELECT owner,table_name FROM pipeline_test where owner != 'SYS')
  			)
		)
	*/

	function prow_test ( csr_in refcur_t ) return retrec_set pipelined
	is
		retrec retrec_t;
		inrec csr_in%rowtype;
	begin
		loop
			fetch csr_in into inrec;
			exit when csr_in%notfound;
			retrec.owner := inrec.owner;
			retrec.table_name := inrec.table_name;
			pipe row(retrec);
		end loop;
		close csr_in;
		return;
	end;

   --=============================================================
	--== function prow_test2(owner_in varchar2 default null)
	--==  return rows from the hardcoded cursor
	--==  optionally filter by owner
   --=============================================================
	
	function prow_test2 ( owner_in varchar2 default null ) return retrec_set pipelined
	is
		retrec retrec_t;
	begin
		for csrec in (
    		select owner,table_name
			from pipeline_test
			where owner like decode(nvl(owner_in,'-NA-'), '-NA-','%',upper(owner_in))
		)
		loop
			retrec.owner := csrec.owner;
			retrec.table_name := csrec.table_name;
			pipe row(retrec);
		end loop;
		return;
	end;

	

end;
/

show errors package body pipeline_01


--@@pipeline-01-test

