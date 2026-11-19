/// Build number of this app (the part after `+` in pubspec.yaml `version:`).
///
/// Used by the minimum-build gate (migration 0054/0057, FIX B). Keep in sync
/// with pubspec.yaml; test/core/version/app_version_test.dart fails if they differ.
const int kAppBuildNumber = 6;

/// Version name of this app (the part before `+` in pubspec.yaml `version:`).
/// Shown on the splash screen. Kept in sync by the same test.
const String kAppVersionName = '1.0.5';
