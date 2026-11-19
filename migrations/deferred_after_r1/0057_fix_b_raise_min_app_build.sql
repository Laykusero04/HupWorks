-- ============================================================================
-- Migration 0057 — minimum app build gate (T-0128).
--
-- !!  APPLY ONLY AFTER app R1 IS RELEASED in the stores, together with / right
-- !!  after 0055.  Requires 0054 (creates app_config).
-- !!  You MUST edit the four values below. The script RAISES AN EXCEPTION and
-- !!  changes nothing while they are still the placeholders.
--
-- Who this protects: only builds that contain the gate, i.e. R1 and later.
-- Builds released BEFORE R1 (build 5 and earlier) have no gate: they never read
-- app_config, so this migration does nothing for them (after 0055 they just
-- fail with permission errors). See the banner of 0055.
--
-- R1 CHECKLIST (do together, in the same R1 commit):
--   * bump pubspec.yaml `version: x.y.z+N` so N > 5, AND
--   * set kAppBuildNumber in lib/core/version/app_build.dart to the same N
--     (test/core/version/app_version_test.dart fails if they differ).
--   * The minimum below must be <= N of the R1 release for BOTH platforms,
--     otherwise R1 blocks itself. Build numbers are the part after + in version.
--
-- The app fails OPEN: if the check cannot be read (offline / error), the
-- app is not blocked. Builds below the minimum see a blocking update screen
-- (lib/core/version/app_version_gate.dart); the button needs the store URL.
-- ============================================================================

do $$
declare
  -- EDIT ALL FOUR. NULL / 0 mean "not edited yet".
  v_min_ios     int  := null;   -- build number of the R1 iOS release (must be > 5)
  v_min_android int  := null;   -- build number of the R1 Android release (must be > 5)
  v_url_ios     text := null;   -- App Store URL (https://...)
  v_url_android text := null;   -- Play Store URL (https://...)
begin
  if v_min_ios is null or v_min_android is null
     or v_min_ios <= 5 or v_min_android <= 5 then
    raise exception '0057: set v_min_ios and v_min_android to the R1 build numbers (> 5). Nothing changed.';
  end if;
  if v_url_ios is null or v_url_android is null
     or v_url_ios !~ '^https://' or v_url_android !~ '^https://' then
    raise exception '0057: set v_url_ios and v_url_android to the store URLs (https://...). Nothing changed.';
  end if;

  update public.app_config
  set min_build_ios = v_min_ios,
      min_build_android = v_min_android,
      update_url_ios = v_url_ios,
      update_url_android = v_url_android,
      updated_at = now()
  where id = 1;
end $$;
