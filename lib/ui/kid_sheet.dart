import 'package:flutter/material.dart';

/// Kid-friendly bottom sheet shell: rounded top (via theme), drag handle,
/// emoji title row, then the content.
Future<T?> showKidSheet<T>({
  required BuildContext context,
  required String emoji,
  required String title,
  required Widget child,
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
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
          ),
          Flexible(child: child),
        ],
      ),
    ),
  );
}
