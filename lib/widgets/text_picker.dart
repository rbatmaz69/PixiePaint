import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/tool.dart';
import '../ui/app_theme.dart';
import '../ui/kid_dialog.dart';
import '../ui/kid_sheet.dart';
import '../ui/pixie_palette.dart';

/// The most-asked-for thing a child cannot do with a brush: put their own
/// name on the picture.
///
/// Twelve characters, because the word is written as one line at a fixed
/// size and a sentence would run off the paper. Whatever is typed is shown
/// above the field in the colour and roughly the size it will land in, so a
/// child who cannot read still sees what they are about to place.
Future<void> showTextPicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: '🔤',
    title: context.l10n.textPickerTitle,
    builder: (sheetContext) => _TextSheet(controller: controller),
  );
}

class _TextSheet extends StatefulWidget {
  const _TextSheet({required this.controller});

  final CanvasController controller;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  /// Owned by this State and disposed with it.
  ///
  /// The rename dialog taught this the hard way: a controller freed while
  /// the closing animation is still rebuilding the field throws on the last
  /// few frames. It lives exactly as long as the widget that reads it.
  late final TextEditingController _field =
      TextEditingController(text: widget.controller.stampText ?? '');

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _place() {
    final text = _field.text.trim();
    if (text.isEmpty) return;
    widget.controller.stampText = text;
    widget.controller.selectTool(ToolKind.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        // The keyboard is up the whole time this sheet is open.
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The preview, in the paint colour. Empty on purpose when nothing
          // is typed: a placeholder word would be a promise.
          SizedBox(
            height: 52,
            child: Center(
              child: Text(
                _field.text.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: 34,
                  color: widget.controller.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: PixieTokens.gapSmall),
          TextField(
            controller: _field,
            autofocus: true,
            maxLength: 12,
            textCapitalization: TextCapitalization.words,
            textAlign: TextAlign.center,
            inputFormatters: [
              // One line, always: a newline here would be written straight
              // through the picture as a box glyph.
              FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _place(),
            decoration: InputDecoration(
              hintText: context.l10n.textPickerHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PixieTokens.rSmall),
              ),
            ),
          ),
          const SizedBox(height: PixieTokens.gapSmall),
          KidDialogButton(
            emoji: '👉',
            label: context.l10n.textPickerPlace,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PixiePalette.periwinkleLight, PixiePalette.indigo],
            ),
            onTap: _place,
          ),
        ],
      ),
    );
  }
}
