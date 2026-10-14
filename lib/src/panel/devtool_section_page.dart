import 'package:flutter/material.dart';

import '../core/devtool_scope.dart';
import '../core/devtool_tool.dart';
import '../keys.dart';
import '../theme/devtool_theme.dart';

/// Lists the cards of every tool belonging to [section].
class DevtoolSectionPage extends StatelessWidget {
  const DevtoolSectionPage({super.key, required this.section});

  final DevtoolSection section;

  @override
  Widget build(BuildContext context) {
    final controller = DevtoolScope.of(context);
    final tools = controller.toolsOf(section);

    return Scaffold(
      key: DevtoolKeys.sectionPage(section.id),
      appBar: AppBar(title: Text(section.title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(DevtoolSpacing.padding),
        itemCount: tools.length,
        separatorBuilder: (_, _) => const SizedBox(height: DevtoolSpacing.gap),
        itemBuilder: (context, index) => tools[index].build(context, controller),
      ),
    );
  }
}
