select table_name, 
       constraint_name, 
       constraint_type 
from information_schema.table_constraints tc 
where constraint_type = 'PRIMARY KEY'
and constraint_schema = 'public';