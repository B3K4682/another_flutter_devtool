import 'devtool_tool.dart';

/// Registry of tools added by the app, keyed by [DevtoolTool.id].
///
/// Register custom tools once, before `runApp`. A tool whose id matches one
/// that a section ships with replaces that built-in tool.
abstract final class DevtoolTools {
  static final Map<String, DevtoolTool> _tools = {};

  /// Tools registered by the app, in registration order.
  static List<DevtoolTool> get registered => _tools.values.toList(growable: false);

  /// Register tool to be displayed in the devtool panel.
  static void register(DevtoolTool tool) => _tools[tool.id] = tool;

  /// Register multiple tools at once.
  static void registerAll(Iterable<DevtoolTool> tools) => tools.forEach(register);

  /// Unregister a tool.
  static void unregister(String toolId) => _tools.remove(toolId);

  /// Clear all registered tools.
  static void clear() => _tools.clear();
}
