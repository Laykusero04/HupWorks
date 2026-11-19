-- Rollback for 0057: remove the gate (everyone can open the app again).
update public.app_config set min_build_ios = 0, min_build_android = 0, updated_at = now() where id = 1;
