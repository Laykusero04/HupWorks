-- Rollback for 0052. Destroys the admin allow-list and audit log.
-- Without these tables the admin API fails closed (every request is 403).
drop table if exists public.admin_audit_log;
drop table if exists public.admin_users;
