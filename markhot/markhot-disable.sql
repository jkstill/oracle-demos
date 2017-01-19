
-- disable use of dbms_shared_pool.markhot

alter system reset "_kgl_hot_object_copies" scope=spfile;

