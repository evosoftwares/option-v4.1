-- Simple migration to fix ownership issues
-- We need to fix the ownership of approval_status_enum type

-- Check current ownership
SELECT typname, rolname 
FROM pg_type t 
JOIN pg_roles r ON t.typowner = r.oid 
WHERE typname = 'approval_status_enum';

-- Try to change ownership (this might fail if we don't have permissions)
-- ALTER TYPE public.approval_status_enum OWNER TO postgres;