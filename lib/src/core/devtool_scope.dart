import 'package:flutter/widgets.dart';

import 'devtool_controller.dart';

/// Exposes the [DevtoolController] to the launcher, the panel and all tools.
class DevtoolScope extends InheritedNotifier<DevtoolController> {
  const DevtoolScope({super.key, required DevtoolController controller, required super.child})
    : super(notifier: controller);

  static DevtoolController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DevtoolScope>();
    assert(scope?.notifier != null, 'No DevtoolScope found in context');
    return scope!.notifier!;
  }
}
