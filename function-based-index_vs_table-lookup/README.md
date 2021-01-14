

@schema.sql
@stats-fake
@q1 - should use bad_idx index
@sql-patch
@q1 - should use comp_id_idx
@fbi - create FBI index

flush shared_pool, log out, log in

@q1 - should use the new FBI index

