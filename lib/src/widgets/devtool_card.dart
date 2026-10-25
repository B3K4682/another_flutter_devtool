import 'package:flutter/material.dart';

import '../theme/devtool_theme.dart';
import 'devtool_info_modal.dart';

/// Surface used by every tool: leading icon, title and an optional info modal.
class DevtoolCard extends StatelessWidget {
  const DevtoolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.description,
    this.infoButtonKey,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// When set, an info button opens a modal explaining what the card does.
  final String? description;

  /// Key for the info button (for testing), optional.
  final Key? infoButtonKey;

  @override
  Widget build(BuildContext context) {
    final description = this.description;

    return Container(
      decoration: BoxDecoration(
        color: DevtoolColors.surface,
        borderRadius: BorderRadius.circular(DevtoolSpacing.radius),
        border: Border.all(color: DevtoolColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DevtoolSpacing.padding, 10, 6, 10),
            child: Row(
              children: [
                _CardIcon(icon: icon),
                const SizedBox(width: DevtoolSpacing.gap),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
                if (description != null)
                  IconButton(
                    key: infoButtonKey,
                    tooltip: 'About $title',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    onPressed: () => showDevtoolInfoModal(context, title: title, description: description, icon: icon),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(DevtoolSpacing.padding), child: child),
        ],
      ),
    );
  }
}

class _CardIcon extends StatelessWidget {
  const _CardIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: DevtoolColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: DevtoolColors.primary),
    );
  }
}
