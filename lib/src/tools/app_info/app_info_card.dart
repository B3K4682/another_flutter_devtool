import 'package:flutter/material.dart';

import '../../core/devtool_controller.dart';
import '../../keys.dart';
import '../../theme/devtool_theme.dart';
import '../../widgets/devtool_card.dart';
import '../../widgets/devtool_info_row.dart';
import '../../widgets/devtool_switch_row.dart';
import 'app_info_data.dart';
import 'app_info_state.dart';
import 'app_info_tool.dart';

/// Card rendering the values collected by [AppInfoTool].
class AppInfoCard extends StatefulWidget {
  const AppInfoCard({super.key, required this.tool, required this.controller});

  final AppInfoTool tool;
  final DevtoolController controller;

  @override
  State<AppInfoCard> createState() => _AppInfoCardState();
}

class _AppInfoCardState extends State<AppInfoCard> {
  AppInfoState? get _state => widget.controller.toolState<AppInfoState>(AppInfoTool.toolId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _state?.refreshStartup());
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;

    return DevtoolCard(
      key: DevtoolKeys.toolCard(widget.tool.id),
      icon: widget.tool.icon,
      title: widget.tool.title,
      description: widget.tool.description,
      infoButtonKey: DevtoolKeys.toolInfoButton(widget.tool.id),
      child: state == null
          ? const _Loading()
          : ListenableBuilder(
              listenable: state,
              builder: (context, _) {
                final data = state.data;
                if (data == null) return const _Loading();
                return _Content(data: data, controller: widget.controller);
              },
            ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.controller});

  final AppInfoData data;
  final DevtoolController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DevtoolInfoRow(label: 'App version', value: data.versionLabel),
        DevtoolInfoRow(label: 'Device model', value: data.deviceModel),
        DevtoolInfoRow(label: 'OS version', value: data.osVersion),
        DevtoolInfoRow(label: 'Current flavor', value: data.flavor, valueColor: _flavorColor(data.flavor)),
        DevtoolInfoRow(label: 'App startup time', value: data.startupLabel),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1),
        ),
        DevtoolSwitchRow(
          label: 'Show version below launcher',
          subtitle: data.badgeLabel,
          value: controller.showVersionBadge,
          onChanged: controller.setShowVersionBadge,
        ),
      ],
    );
  }

  Color? _flavorColor(String flavor) => switch (flavor) {
        'Debug' => DevtoolColors.warning,
        'Profile' => DevtoolColors.info,
        'Release' => DevtoolColors.success,
        _ => null,
      };
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: DevtoolColors.primary),
        ),
      ),
    );
  }
}
