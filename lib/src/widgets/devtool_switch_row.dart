import 'package:flutter/material.dart';

import '../theme/devtool_theme.dart';

/// Toggle row used inside devtool cards.
class DevtoolSwitchRow extends StatelessWidget {
  const DevtoolSwitchRow({super.key, required this.label, required this.value, required this.onChanged, this.subtitle});

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle, style: theme.textTheme.labelSmall)],
            ],
          ),
        ),
        const SizedBox(width: DevtoolSpacing.gap),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
