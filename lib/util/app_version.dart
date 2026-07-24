/// The app version, for the one place that needs it in plain text: the
/// problem report a parent can share.
///
/// Deliberately a constant rather than a `package_info_plus` lookup — a
/// whole plugin for one string is not worth it in an app that ships no
/// network code. `test/app_version_test.dart` compares it against
/// `pubspec.yaml`, so it cannot quietly fall behind.
const String kAppVersion = '8.2.0';
