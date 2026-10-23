import 'package:flutter/material.dart';

import '../core/devtool_scope.dart';
import '../core/devtool_tool.dart';
import '../keys.dart';
import '../theme/devtool_theme.dart';
import 'devtool_section_page.dart';

/// Home screen of the devtool: a grid of sections, two per row.
class DevtoolPanel extends StatelessWidget {
  const DevtoolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final sections = DevtoolScope.of(context).sections;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onClose();
      },
      child: Scaffold(
        key: DevtoolKeys.panel,
        appBar: AppBar(
          title: const Text('Another Flutter Devtool'),
          actions: [
            IconButton(
              key: DevtoolKeys.closeButton,
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, color: DevtoolColors.textPrimary),
              onPressed: onClose,
            ),
          ],
        ),
        body: sections.isEmpty
            ? const _EmptyState()
            : GridView.count(
                padding: const EdgeInsets.all(DevtoolSpacing.padding),
                crossAxisCount: 2,
                crossAxisSpacing: DevtoolSpacing.gap,
                mainAxisSpacing: DevtoolSpacing.gap,
                childAspectRatio: 2.5,
                children: <Widget>[
                  for (final section in sections) _SectionCard(section: section),
                ],
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final DevtoolSection section;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(DevtoolSpacing.radius);

    return Material(
      color: DevtoolColors.surface,
      borderRadius: borderRadius,
      child: InkWell(
        key: DevtoolKeys.sectionCard(section.id),
        borderRadius: borderRadius,
        hoverColor: DevtoolColors.hover,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) =>
                section.buildPage(context, DevtoolScope.of(context)) ?? DevtoolSectionPage(section: section),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(DevtoolSpacing.padding),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: DevtoolColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DevtoolColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(section.icon, size: 20, color: DevtoolColors.primary),
              ),
              const SizedBox(width: DevtoolSpacing.gap),
              Expanded(
                child: Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No sections configured.\nPass sections: [GeneralSection()] to DevtoolConfig.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
