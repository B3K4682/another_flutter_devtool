import 'package:flutter/material.dart';

import '../keys.dart';

/// Full-screen devtool panel; empty in v1.
class DevtoolPanel extends StatelessWidget {
  const DevtoolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onClose();
      },
      child: Scaffold(
        key: DevtoolKeys.panel,
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Another Flutter Devtool', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              key: DevtoolKeys.closeButton,
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: onClose,
            ),
          ],
        ),
        body: const SizedBox.expand(),
      ),
    );
  }
}
