import 'package:flutter/material.dart';

import 'config/devtool_config.dart';
import 'core/devtool_controller.dart';
import 'core/devtool_scope.dart';
import 'core/devtool_storage.dart';
import 'launcher/draggable_launcher.dart';
import 'panel/devtool_panel.dart';
import 'theme/devtool_theme.dart';
import 'tools/app_info/app_info_state.dart';
import 'tools/app_info/app_info_tool.dart';
import 'tools/app_info/startup_tracker.dart';

/// Wraps an app and overlays the devtool launcher and panel on top of it.
class AnotherFlutterDevtool extends StatefulWidget {
  const AnotherFlutterDevtool({
    super.key,
    required this.config,
    required this.child,
  });

  /// main Configuration for the devtool.
  final DevtoolConfig config;
  final Widget child;

  /// Call as the first line of `main()` for an accurate startup measurement.
  static void markStartup() => DevtoolStartupTracker.instance.markStart();

  @override
  State<AnotherFlutterDevtool> createState() => _AnotherFlutterDevtoolState();
}

class _AnotherFlutterDevtoolState extends State<AnotherFlutterDevtool> {
  late final bool _launcherVisible = widget.config.launcher.initiallyVisible;
  late final DevtoolController _controller;
  bool _panelOpen = false;
  Offset? _launcherOffset;

  @override
  void initState() {
    super.initState();
    _controller = DevtoolController(
      config: widget.config,
      storage: widget.config.storage ?? SharedPreferencesDevtoolStorage(),
    );
    if (widget.config.enabled) {
      DevtoolStartupTracker.instance.trackFirstFrame();
      _controller.init();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openPanel() => setState(() => _panelOpen = true);

  void _closePanel() => setState(() => _panelOpen = false);

  @override
  Widget build(BuildContext context) {
    if (!widget.config.enabled) return widget.child;

    final showLauncher = widget.config.launcher.enabled && _launcherVisible && !_panelOpen;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery.fromView(
        view: View.of(context),
        child: DevtoolScope(
          controller: _controller,
          child: Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (_panelOpen)
                Positioned.fill(
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: DevtoolTheme.dark(),
                    home: DevtoolPanel(onClose: _closePanel),
                  ),
                ),
              if (showLauncher)
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => DraggableLauncher(
                    offset: _launcherOffset,
                    onMoved: (offset) => setState(() => _launcherOffset = offset),
                    onTap: _openPanel,
                    versionLabel: _versionLabel,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _versionLabel {
    if (!_controller.showVersionBadge) return null;
    return _controller.toolState<AppInfoState>(AppInfoTool.toolId)?.data?.badgeLabel;
  }
}
