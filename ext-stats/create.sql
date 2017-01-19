
col name format a10
col color format a5
col tranny format a5

drop table cars purge;

create table cars (
	id number,
	brand varchar2(10),
	color varchar2(5),
	tranny varchar2(5),
	seats varchar2(6),
	constraint cars_pk primary key (id),
	constraint car_color check (color in ('RED','BEIGE')),
	constraint car_tranny check (tranny in ('STICK','AUTO'))
)
/

insert into cars
select
	level id
	, dbms_random.string('L',trunc(dbms_random.value(4,10))) name
	, case  		
		when mod(level,2) = 0 then 'BEIGE'
		else 'RED'
	end color
	, case 
		when mod(level,2) != 0  -- red cars
		then decode(trunc(dbms_random.value(1,3)),1,'STICK','AUTO')
		else 'AUTO'
	end tranny
	, null
from dual connect by level <= 20000
/

update cars set seats = 'VINYL' where tranny='AUTO';
update cars set seats = 'RECARO' where tranny = 'STICK';

create index cars_color_idx on cars(color);
create index cars_tranny_idx on cars(tranny);
create index cars_seats_idx on cars(seats);

