import 'package:flutter/material.dart';

import '../gallery/artwork_store.dart';
import '../l10n/l10n.dart';
import '../models/profile.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/kid_sheet.dart';
import '../ui/pixie_palette.dart';
import '../util/profiles.dart';
import '../util/progress.dart';
import '../util/sfx.dart';
import 'parental_gate.dart';

/// The profile switcher: big bubbles the kid can freely tap to become the
/// active painter, plus a parent-gated "manage" row for adding, renaming and
/// removing profiles.
Future<void> showProfileSheet(BuildContext context) {
  return showKidSheet<void>(
    context: context,
    emoji: '👋',
    title: context.l10n.profileTitle,
    child: const _ProfileSheetBody(),
  );
}

class _ProfileSheetBody extends StatefulWidget {
  const _ProfileSheetBody();

  @override
  State<_ProfileSheetBody> createState() => _ProfileSheetBodyState();
}

class _ProfileSheetBodyState extends State<_ProfileSheetBody> {
  final _store = ProfileStore.instance;

  Future<void> _switch(Profile profile) async {
    if (profile.id != _store.active.id) {
      _store.switchTo(profile.id);
      await Progress.instance.switchProfile(profile.id);
      Sfx.instance.pop();
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _manage() async {
    if (!await ParentalGate.show(context)) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _ManageProfiles(),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (final profile in _store.profiles)
                  _ProfileBubble(
                    profile: profile,
                    selected: profile.id == _store.active.id,
                    onTap: () => _switch(profile),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            KidDialogTextButton(
              label: context.l10n.profileManage,
              onTap: _manage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBubble extends StatelessWidget {
  const _ProfileBubble({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final Profile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      playTick: false,
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? PixiePalette.grape : Colors.transparent,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PixiePalette.grape
                        .withValues(alpha: selected ? 0.3 : 0.12),
                    blurRadius: selected ? 14 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(profile.emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 6),
            Text(
              profile.name.isEmpty ? context.l10n.profileDefaultName : profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Parent-only management list: add, rename, change face, remove.
class _ManageProfiles extends StatefulWidget {
  const _ManageProfiles();

  @override
  State<_ManageProfiles> createState() => _ManageProfilesState();
}

class _ManageProfilesState extends State<_ManageProfiles> {
  final _store = ProfileStore.instance;

  Future<void> _edit(Profile? existing) async {
    final result = await showModalBottomSheet<_ProfileDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProfileEditor(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _store.addProfile(name: result.name, emoji: result.emoji);
      await Progress.instance.switchProfile(_store.active.id);
    } else {
      await _store.updateProfile(existing.id,
          name: result.name, emoji: result.emoji);
    }
    if (mounted) setState(() {});
  }

  /// Removing a kid asks the parent what happens to that kid's pictures:
  /// hand them to the primary profile, or delete them for good.
  Future<void> _remove(Profile profile) async {
    final choice = await showKidDialog<String>(
      context: context,
      emoji: '🗑️',
      title: context.l10n.profileRemoveTitle(
          profile.name.isEmpty ? context.l10n.profileDefaultName : profile.name),
      body: Text(context.l10n.profileRemoveBody, textAlign: TextAlign.center),
      actions: [
        Builder(
          builder: (c) => KidDialogButton(
            emoji: '📥',
            label: context.l10n.profileRemoveKeepArt,
            onTap: () => Navigator.pop(c, 'keep'),
          ),
        ),
        Builder(
          builder: (c) => KidDialogTextButton(
            label: context.l10n.profileRemoveDeleteArt,
            onTap: () => Navigator.pop(c, 'delete'),
          ),
        ),
        Builder(
          builder: (c) => KidDialogTextButton(
            label: context.l10n.gateCancel,
            onTap: () => Navigator.pop(c),
          ),
        ),
      ],
    );
    if (choice == null) return;
    final primaryId = _store.primary.id;
    for (final artwork in await ArtworkStore.list()) {
      if (artwork.profileId != profile.id) continue;
      if (choice == 'delete') {
        await ArtworkStore.delete(artwork);
      } else {
        await ArtworkStore.updateMeta(artwork.copyWith(profileId: primaryId));
      }
    }
    final wasActive = profile.id == _store.active.id;
    await _store.removeProfile(profile.id);
    // Removing the active kid switches the store to the primary; reload its
    // progress so the rest of the app sees the right rewards.
    if (wasActive) await Progress.instance.switchProfile(_store.active.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(context.l10n.profileManage,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final profile in _store.profiles)
              ListTile(
                leading:
                    Text(profile.emoji, style: const TextStyle(fontSize: 30)),
                title: Text(profile.name.isEmpty
                    ? context.l10n.profileDefaultName
                    : profile.name),
                subtitle: profile.id == _store.primary.id
                    ? Text(context.l10n.profilePrimaryBadge)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: context.l10n.renameAction,
                      onPressed: () => _edit(profile),
                    ),
                    // The primary can never be removed — it owns the
                    // null-profile fallback, so it must always exist.
                    if (profile.id != _store.primary.id)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: context.l10n.deleteAction,
                        onPressed: () => _remove(profile),
                      ),
                  ],
                ),
              ),
            if (_store.canAddMore)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: KidDialogButton(
                  emoji: '➕',
                  label: context.l10n.profileAdd,
                  onTap: () => _edit(null),
                ),
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfileDraft {
  const _ProfileDraft(this.name, this.emoji);
  final String name;
  final String emoji;
}

/// Name field + a grid of animal faces.
class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.existing});

  final Profile? existing;

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late String _emoji = widget.existing?.emoji ?? kProfileEmojis.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null
                ? context.l10n.profileAdd
                : context.l10n.renameAction,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 14,
            textCapitalization: TextCapitalization.words,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(
              counterText: '',
              hintText: context.l10n.profileNameHint,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final emoji in kProfileEmojis)
                Bouncy(
                  playTick: false,
                  onTap: () => setState(() => _emoji = emoji),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _emoji == emoji
                          ? PixiePalette.grapeLight
                          : const Color(0xFFF5F0E8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _emoji == emoji
                            ? PixiePalette.grape
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          KidDialogButton(
            emoji: '💾',
            label: context.l10n.renameSave,
            onTap: () => Navigator.pop(
                context, _ProfileDraft(_name.text.trim(), _emoji)),
          ),
        ],
      ),
    );
  }
}
