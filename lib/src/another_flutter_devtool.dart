import 'package:flutter/material.dart';

import 'config/devtool_config.dart';
import 'launcher/draggable_launcher.dart';
import 'panel/devtool_panel.dart';

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

  @override
  State<AnotherFlutterDevtool> createState() => _AnotherFlutterDevtoolState();
}

class _AnotherFlutterDevtoolState extends State<AnotherFlutterDevtool> {
  late final bool _launcherVisible = widget.config.launcher.initiallyVisible;
  bool _panelOpen = false;
  Offset? _launcherOffset;

  void _openPanel() => setState(() => _panelOpen = true);

  void _closePanel() => setState(() => _panelOpen = false);

  @override
  Widget build(BuildContext context) {
    if (!widget.config.enabled) return widget.child;

    final showLauncher =
        widget.config.launcher.enabled && _launcherVisible && !_panelOpen;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery.fromView(
        view: View.of(context),
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (_panelOpen)
              Positioned.fill(
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData.dark(),
                  home: DevtoolPanel(onClose: _closePanel),
                ),
              ),
            if (showLauncher)
              DraggableLauncher(
                offset: _launcherOffset,
                onMoved: (offset) => setState(() => _launcherOffset = offset),
                onTap: _openPanel,
              ),
          ],
        ),
      ),
    );
  }
}
