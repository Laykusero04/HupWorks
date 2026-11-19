/// Build number of this app (the part after `+` in pubspec.yaml `version:`).
///
/// Used by the minimum-build gate (migration 0054/0057, FIX B). Keep in sync
/// with pubspec.yaml; test/core/version/app_version_test.dart fails if they differ.
const int kAppBuildNumber = 5;
