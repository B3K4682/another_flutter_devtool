import 'package:flutter/widgets.dart';

/// Keys for locating devtool widgets in tests.
abstract final class DevtoolKeys {
  static const launcher = ValueKey('another_flutter_devtool.launcher');
  static const panel = ValueKey('another_flutter_devtool.panel');
  static const closeButton = ValueKey('another_flutter_devtool.close_button');
}
