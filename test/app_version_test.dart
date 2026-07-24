import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/app_version.dart';

/// A version string kept by hand rots by hand. It appears in the problem
/// report a parent shares, which is exactly the place where "7.4.2" printed
/// under a 7.6 build sends whoever reads it looking in the wrong version.
void main() {
  test('kAppVersion matches the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+', multiLine: true)
            .firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec has no version: <name>+<build>');
    expect(kAppVersion, match!.group(1),
        reason: 'bump lib/util/app_version.dart together with the pubspec');
  });
}
