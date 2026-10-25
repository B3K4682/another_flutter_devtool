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
  const AnotherFlutterDevtool({super.key, required this.config, required this.child});

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

  @override
  Widget build(BuildContext context) {
    if (!widget.config.enabled) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery.fromView(
        view: View.of(context),
        child: DevtoolScope(
          controller: _controller,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final panelOpen = _controller.isPanelOpen;
              final showLauncher = widget.config.launcher.enabled && _launcherVisible && !panelOpen;
              return Stack(
                children: [
                  Positioned.fill(child: widget.child),
                  if (panelOpen)
                    Positioned.fill(
                      child: MaterialApp(
                        debugShowCheckedModeBanner: false,
                        theme: DevtoolTheme.dark(),
                        home: DevtoolPanel(onClose: _controller.closePanel),
                      ),
                    ),
                  if (showLauncher)
                    DraggableLauncher(
                      offset: _launcherOffset,
                      onMoved: (offset) => setState(() => _launcherOffset = offset),
                      onTap: _controller.openPanel,
                      versionLabel: _versionLabel,
                    ),
                ],
              );
            },
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
