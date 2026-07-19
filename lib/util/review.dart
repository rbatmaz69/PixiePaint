import 'package:in_app_review/in_app_review.dart';

import 'settings.dart';

/// Counts a successful share and asks the OS for the review prompt exactly
/// once, after the third share. Only called from parent-gated share flows,
/// so the prompt never appears in the pure kid context (Families policy).
Future<void> countShareAndMaybeReview() async {
  final settings = Settings.instance;
  await settings.registerShare();
  if (settings.shareCount < 3 || settings.reviewRequested) return;
  await settings.markReviewRequested();
  try {
    final review = InAppReview.instance;
    if (await review.isAvailable()) await review.requestReview();
  } catch (_) {
    // The OS quota or a missing store is not our problem to surface.
  }
}

/// Settings tile: open the store listing directly (requestReview can be
/// silently dropped by the OS quota).
Future<void> openStoreListing() async {
  try {
    await InAppReview.instance.openStoreListing();
  } catch (_) {}
}
