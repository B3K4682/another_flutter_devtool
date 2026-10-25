import 'package:flutter/material.dart';

import '../../core/devtool_controller.dart';
import '../../keys.dart';
import '../../theme/devtool_theme.dart';
import '../../widgets/devtool_card.dart';
import 'configuration_tool.dart';

/// Card rendering the controls of [ConfigurationTool].
class ConfigurationCard extends StatefulWidget {
  const ConfigurationCard({super.key, required this.tool, required this.controller});

  final ConfigurationTool tool;
  final DevtoolController controller;

  @override
  State<ConfigurationCard> createState() => _ConfigurationCardState();
}

class _ConfigurationCardState extends State<ConfigurationCard> {
  final _routeController = TextEditingController();

  @override
  void dispose() {
    _routeController.dispose();
    super.dispose();
  }

  void _go() {
    final onNavigate = widget.tool.onNavigate;
    final input = _routeController.text.trim();
    if (onNavigate == null || input.isEmpty) return;
    final route = input.startsWith('/') ? input : '/$input';
    widget.controller.closePanel();
    onNavigate(route);
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final theme = Theme.of(context);
    final enabled = tool.onNavigate != null;

    return DevtoolCard(
      key: DevtoolKeys.toolCard(tool.id),
      icon: tool.icon,
      title: tool.title,
      description: tool.description,
      infoButtonKey: DevtoolKeys.toolInfoButton(tool.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('NAVIGATION', style: theme.textTheme.labelSmall),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: DevtoolKeys.configurationRouteField,
                  controller: _routeController,
                  enabled: enabled,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '/example',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _go(),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: DevtoolKeys.configurationGoButton,
                style: TextButton.styleFrom(foregroundColor: DevtoolColors.primary),
                onPressed: enabled ? _go : null,
                child: const Text('Go'),
              ),
            ],
          ),
          if (!enabled)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Pass ConfigurationTool(onNavigate: ...) to GeneralSection to enable',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
