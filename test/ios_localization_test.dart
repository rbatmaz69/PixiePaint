import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The two iOS permission dialogs, in all nine languages.
///
/// iOS shows `NSPhotoLibraryUsageDescription` and its Add sibling in the
/// **system** language of the device, not in the app's — until v7.7 a Spanish
/// iPhone read a German sentence, and Apple checks these texts.
///
/// The failure mode this file exists for is subtler than a missing
/// translation: a `.lproj` file on disk does **nothing** unless the Xcode
/// project references it. Everything below is therefore checked twice, once
/// on disk and once in `project.pbxproj`. Nobody can currently build the iOS
/// app on this machine (`flutter doctor`: Xcode incomplete), so this test is
/// the only automatic guard the wiring has.
void main() {
  /// Derived from the ARB files rather than hardcoded: a tenth app language
  /// then cannot quietly ship without a permission text.
  final languages = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .map((f) => RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)?.group(1))
      .whereType<String>()
      .toList()
    ..sort();

  const keys = [
    'NSPhotoLibraryUsageDescription',
    'NSPhotoLibraryAddUsageDescription',
  ];

  String infoPlist() => File('ios/Runner/Info.plist').readAsStringSync();
  String pbxproj() =>
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  test('the app has the nine languages this test expects', () {
    expect(languages, ['de', 'en', 'es', 'fr', 'it', 'nl', 'pl', 'pt', 'tr']);
  });

  for (final lang in languages) {
    group(lang, () {
      final file = File('ios/Runner/$lang.lproj/InfoPlist.strings');

      test('has an InfoPlist.strings with both permission texts', () {
        expect(file.existsSync(), isTrue,
            reason: 'missing ios/Runner/$lang.lproj/InfoPlist.strings');
        final content = file.readAsStringSync();
        for (final key in keys) {
          final match =
              RegExp('"$key"\\s*=\\s*"([^"]+)";').firstMatch(content);
          expect(match, isNotNull, reason: '$lang: $key is missing');
          expect(match!.group(1)!.trim(), isNotEmpty,
              reason: '$lang: $key is empty');
        }
      });

      test('is registered in the Xcode project', () {
        // Without the file reference the file is not copied into the bundle,
        // and iOS silently falls back to the German string in Info.plist.
        expect(pbxproj(), contains('$lang.lproj/InfoPlist.strings'),
            reason: '$lang: no PBXFileReference — the file would never reach '
                'the app bundle');
        // Without the region, Xcode ignores the .lproj folder entirely.
        expect(RegExp(r'knownRegions = \(([^)]*)\)').firstMatch(pbxproj())!
            .group(1)!, contains(lang),
            reason: '$lang: not in knownRegions');
      });

      test('is listed in CFBundleLocalizations', () {
        // App Store Connect reads the app's language list from here.
        final block = RegExp(r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
                dotAll: true)
            .firstMatch(infoPlist());
        expect(block, isNotNull, reason: 'CFBundleLocalizations is missing');
        expect(block!.group(1), contains('<string>$lang</string>'));
      });
    });
  }

  test('the variant group is in the Runner target\'s resources', () {
    final src = pbxproj();
    expect(src, contains('name = InfoPlist.strings;'),
        reason: 'no PBXVariantGroup — the nine files are not one localized '
            'resource');
    expect(src, contains('InfoPlist.strings in Resources'),
        reason: 'the group is not in the Resources build phase, so nothing '
            'gets copied');
  });

  test('Info.plist keeps German as the built-in fallback', () {
    // The localized files override these; a device in an unsupported language
    // still needs something to show.
    for (final key in keys) {
      expect(infoPlist(), contains('<key>$key</key>'));
    }
  });
}
