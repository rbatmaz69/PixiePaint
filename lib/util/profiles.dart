import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../gallery/artwork_store.dart';
import '../models/profile.dart';
import 'backup.dart';
import 'json_store.dart';

/// The kids sharing this device. One is active at a time; the active
/// profile decides whose reward progress loads and whose pictures the
/// gallery shows.
///
/// The very first profile is the "primary": artworks and progress made
/// before profiles existed are migrated to it, and any artwork left without
/// a [Profile.id] stamp is treated as belonging to it forever (the eternal
/// fallback, so a half-finished migration can never hide a picture).
class ProfileStore extends ChangeNotifier {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  static const int maxProfiles = 4;

  final List<Profile> profiles = [];
  String? _activeId;

  JsonStore? _store;
  Directory? _docsDir;

  /// The currently selected kid. Falls back to the primary if the stored
  /// active id ever goes missing.
  Profile get active =>
      profiles.firstWhere((p) => p.id == _activeId, orElse: () => primary);

  /// The first profile — owner of unstamped (legacy) artworks.
  Profile get primary => profiles.first;

  bool get canAddMore => profiles.length < maxProfiles;

  Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    await loadFrom(JsonStore(File('${dir.path}/profiles.json')), dir);
  }

  /// Test seam: drive from any store + documents dir.
  Future<void> loadFrom(JsonStore store, Directory docsDir) async {
    _store = store;
    _docsDir = docsDir;
    final json = await store.read();
    if (json != null) {
      profiles.addAll(((json['profiles'] as List?) ?? [])
          .map((e) => Profile.fromJson((e as Map).cast<String, dynamic>())));
      _activeId = json['activeProfileId'] as String?;
    }
    if (profiles.isEmpty) {
      await _migrate(docsDir);
    }
    if (!profiles.any((p) => p.id == _activeId)) {
      _activeId = profiles.first.id;
    }
  }

  /// First run with profiles: create the primary and adopt any pre-profiles
  /// data. Idempotent — only ever runs while [profiles] is empty.
  Future<void> _migrate(Directory docsDir) async {
    final first = Profile(id: const Uuid().v4(), name: '', emoji: '🦄');
    profiles.add(first);
    _activeId = first.id;

    // Legacy progress.json → progress_<id>.json, keeping the original as a
    // backup in case anything goes wrong.
    try {
      final legacy = File('${docsDir.path}/progress.json');
      final target = File('${docsDir.path}/progress_${first.id}.json');
      if (await legacy.exists() && !await target.exists()) {
        await legacy.copy(target.path);
      }
    } catch (_) {}

    // Stamp existing pictures with the primary profile. Best-effort: the
    // null-fallback in the gallery covers anything missed here.
    try {
      for (final artwork in await ArtworkStore.list()) {
        if (artwork.profileId == null) {
          await ArtworkStore.updateMeta(
              artwork.copyWith(profileId: first.id));
        }
      }
    } catch (_) {}

    await _persist();
  }

  /// Whether an artwork belongs to [profileId] — with the null-owner
  /// artworks always counting for the primary profile.
  bool ownsArtwork(String? artworkProfileId, String profileId) {
    if (artworkProfileId == profileId) return true;
    return artworkProfileId == null && profileId == primary.id;
  }

  Future<Profile> addProfile({
    required String name,
    required String emoji,
    bool simpleTools = false,
  }) async {
    final profile = Profile(
      id: const Uuid().v4(),
      name: name,
      emoji: emoji,
      simpleTools: simpleTools,
    );
    profiles.add(profile);
    _activeId = profile.id;
    notifyListeners();
    await _persist();
    return profile;
  }

  Future<void> updateProfile(String id,
      {String? name, String? emoji, bool? simpleTools}) async {
    final i = profiles.indexWhere((p) => p.id == id);
    if (i < 0) return;
    profiles[i] = profiles[i]
        .copyWith(name: name, emoji: emoji, simpleTools: simpleTools);
    notifyListeners();
    await _persist();
  }

  void switchTo(String id) {
    if (_activeId == id || !profiles.any((p) => p.id == id)) return;
    _activeId = id;
    notifyListeners();
    _persist();
  }

  /// Removes a profile and its reward progress. Artworks are handled by the
  /// caller first (deleted or reassigned) — the store never touches the
  /// gallery on its own. The primary profile can never be removed, so the
  /// null-fallback always has an owner.
  Future<void> removeProfile(String id) async {
    if (id == primary.id || profiles.length <= 1) return;
    profiles.removeWhere((p) => p.id == id);
    if (_activeId == id) _activeId = profiles.first.id;
    try {
      final file = File('${_docsDir?.path}/progress_$id.json');
      if (await file.exists()) await file.delete();
    } catch (_) {}
    notifyListeners();
    await _persist();
  }

  /// Folds the kid list left behind by a backup restore into this device's.
  ///
  /// Restored artworks are stamped with the *backup's* profile ids, so
  /// without their kids they would sit on disk invisible to every filter.
  /// Profiles already known by id are left alone (their name and emoji here
  /// win — this device is the one being used), and [maxProfiles] still
  /// caps the list: pictures belonging to a kid that no longer fits stay on
  /// disk and reappear if a profile is freed up.
  ///
  /// Returns how many kids were added. Idempotent — the side file is
  /// removed once it has been folded in.
  Future<int> mergeRestoredProfiles() async {
    final docs = _docsDir;
    if (docs == null) return 0;
    final file = File('${docs.path}/$kRestoredProfilesFile');
    var added = 0;
    try {
      if (!await file.exists()) return 0;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final known = {for (final p in profiles) p.id};
      for (final raw in (json['profiles'] as List?) ?? []) {
        if (!canAddMore) break;
        final profile = Profile.fromJson((raw as Map).cast<String, dynamic>());
        if (known.contains(profile.id)) continue;
        profiles.add(profile);
        known.add(profile.id);
        added++;
      }
    } catch (_) {
      // A damaged side file costs the kid list, not the restore.
    }
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
    if (added > 0) {
      notifyListeners();
      await _persist();
    }
    return added;
  }

  Future<void> _persist() async {
    await _store?.write({
      'profiles': [for (final p in profiles) p.toJson()],
      'activeProfileId': _activeId,
    });
  }

  Future<void> flush() async => _store?.flush();

  @visibleForTesting
  void resetForTest() {
    profiles.clear();
    _activeId = null;
    _store = null;
    _docsDir = null;
  }
}
