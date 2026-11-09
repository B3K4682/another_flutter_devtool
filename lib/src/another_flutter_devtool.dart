import 'package:flutter/material.dart';

import 'config/devtool_config.dart';
import 'core/devtool_controller.dart';
import 'core/devtool_scope.dart';
import 'core/devtool_storage.dart';
import 'launcher/draggable_launcher.dart';
import 'network/last_call_overlay.dart';
import 'network/network_call.dart';
import 'network/network_call_details_page.dart';
import 'panel/devtool_panel.dart';
import 'sections/network_section.dart';
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
  final _panelNavigatorKey = GlobalKey<NavigatorState>();
  Offset? _launcherOffset;
  Offset? _lastCallOffset;

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
              final networkSection = _networkSection;
              final showLastCall =
                  !panelOpen && networkSection != null && _controller.boolSetting(NetworkSection.showLastCallKey);
              return Stack(
                children: [
                  Positioned.fill(child: widget.child),
                  if (panelOpen)
                    Positioned.fill(
                      child: MaterialApp(
                        navigatorKey: _panelNavigatorKey,
                        debugShowCheckedModeBanner: false,
                        theme: DevtoolTheme.dark(),
                        home: DevtoolPanel(onClose: _controller.closePanel),
                      ),
                    ),
                  if (showLastCall)
                    LastCallOverlay(
                      recorder: networkSection.recorder,
                      offset: _lastCallOffset,
                      onMoved: (offset) => setState(() => _lastCallOffset = offset),
                      onOpenDetails: (call) => _openCallDetails(networkSection, call),
                      redactedQueryParameters: networkSection.redactedQueryParameters,
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

  NetworkSection? get _networkSection => _controller.sections.whereType<NetworkSection>().firstOrNull;

  void _openCallDetails(NetworkSection section, NetworkCall call) {
    _controller.openPanel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _panelNavigatorKey.currentState;
      if (navigator == null) return;
      navigator
        ..push(MaterialPageRoute<void>(builder: (context) => section.buildPage(context, _controller)))
        ..push(
          MaterialPageRoute<void>(
            builder: (_) => NetworkCallDetailsPage(
              recorder: section.recorder,
              call: call,
              redactedHeaders: section.redactedHeaders,
              redactedQueryParameters: section.redactedQueryParameters,
            ),
          ),
        );
    });
  }

  String? get _versionLabel {
    if (!_controller.showVersionBadge) return null;
    return _controller.toolState<AppInfoState>(AppInfoTool.toolId)?.data?.badgeLabel;
  }
}
