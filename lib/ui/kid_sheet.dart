import 'package:flutter/material.dart';
import 'app_theme.dart';

import 'motion.dart';
import 'pop_in.dart';

/// Kid-friendly bottom sheet shell: rounded top (via theme), drag handle,
/// emoji title row (the emoji pops in), then the content.
///
/// [builder] is handed the sheet route's own context — the one
/// `Navigator.pop` needs to close this sheet and return a result. See
/// `showKidDialog` for why it is a builder and not a plain widget.
Future<T?> showKidSheet<T>({
  required BuildContext context,
  required String emoji,
  required String title,
  required Widget Function(BuildContext sheetContext) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PopIn(
                  from: 0.4,
                  delay: PixieMotion.emojiDelay,
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: PixieTokens.gapSmall),
                Flexible(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
          ),
          Flexible(child: builder(context)),
        ],
      ),
    ),
  );
}
