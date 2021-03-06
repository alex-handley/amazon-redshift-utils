/**********************************************************************************************
Purpose:        View to help find all objects owned by the user to be dropped
Columns -


objtype:        Type of object user has privilege on. Object types are Function,Schema,
                Table or View, Database, Language or Default ACL
objowner:       Object owner 
userid:			    Owner user id
schemaname:     Schema for the object
objname:        Name of the object
ddl:            Generate DDL string to transfer object ownership to new user

Notes:           
                
History:
2017-03-27 adedotua created
2017-04-06 adedotua improvements
2018-01-06 adedotua added ddl column to generate ddl for transferring object ownership
**********************************************************************************************/

CREATE OR REPLACE VIEW admin.v_find_dropuser_objs as 
SELECT owner.objtype,
       owner.objowner,
       owner.userid,
       owner.schemaname,
       owner.objname,
       owner.ddl
FROM (
-- Functions owned by the user
     SELECT 'Function',pgu.usename,pgu.usesysid,nc.nspname,textin (regprocedureout (pproc.oid::regprocedure)),
     'alter function ' ||nc.nspname|| '.' ||textin (regprocedureout (pproc.oid::regprocedure)) || ' owner to ' 
     FROM pg_proc pproc,pg_user pgu,pg_namespace nc
WHERE pproc.pronamespace = nc.oid
AND   pproc.proowner = pgu.usesysid
UNION ALL
-- Databases owned by the user
SELECT 'Database',
       pgu.usename,
       pgu.usesysid,
       NULL,
       pgd.datname,
       'alter database ' ||pgd.datname|| ' owner to '
FROM pg_database pgd,
     pg_user pgu
WHERE pgd.datdba = pgu.usesysid
UNION ALL
-- Schemas owned by the user
SELECT 'Schema',
       pgu.usename,
       pgu.usesysid,
       NULL,
       pgn.nspname,
       'alter schema '||pgn.nspname||' owner to '
FROM pg_namespace pgn,
     pg_user pgu
WHERE pgn.nspowner = pgu.usesysid
UNION ALL
-- Tables or Views owned by the user
SELECT decode(pgc.relkind,
             'r','Table',
             'v','View'
       ) ,
       pgu.usename,
       pgu.usesysid,
       nc.nspname,
       pgc.relname,
       'alter table ' ||nc.nspname|| '.' ||pgc.relname|| ' owner to '
FROM pg_class pgc,
     pg_user pgu,
     pg_namespace nc
WHERE pgc.relnamespace = nc.oid
AND   pgc.relkind IN ('r','v')
AND   pgu.usesysid = pgc.relowner) OWNER ("objtype","objowner","userid","schemaname","objname","ddl") 
WHERE owner.userid > 1;

