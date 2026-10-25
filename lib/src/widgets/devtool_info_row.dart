import 'package:flutter/material.dart';

import '../theme/devtool_theme.dart';

/// Label on the left, value on the right; the building block of info cards.
class DevtoolInfoRow extends StatelessWidget {
  const DevtoolInfoRow({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;

  /// Use only for semantic statuses, never for decoration.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          const Spacer(),
          SelectableText(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? DevtoolColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
