import 'package:flutter/material.dart';

import '../keys.dart';
import '../theme/devtool_theme.dart';

/// Shows the reusable "what does this do" modal used by devtool cards.
Future<void> showDevtoolInfoModal(
  BuildContext context, {
  required String title,
  required String description,
  IconData icon = Icons.info_outline_rounded,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => AlertDialog(
      key: DevtoolKeys.infoModal,
      icon: Icon(icon, color: DevtoolColors.primary),
      iconPadding: const EdgeInsets.only(top: 20, bottom: 8),
      title: Text(title),
      titleTextStyle: Theme.of(context).textTheme.titleMedium,
      content: Text(description),
      contentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: DevtoolColors.textSecondary,
            height: 1.8,
          ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          key: DevtoolKeys.infoModalCloseButton,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
