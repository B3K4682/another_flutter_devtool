import 'package:flutter/foundation.dart';

import '../config/devtool_config.dart';
import 'devtool_storage.dart';
import 'devtool_tool.dart';
import 'devtool_tools_registry.dart';

/// Shared state for the launcher, the panel and every tool.
class DevtoolController extends ChangeNotifier {
  DevtoolController({required this.config, required this.storage});

  /// Settings key for the version label under the launcher.
  static const showVersionBadgeKey = 'another_flutter_devtool.show_version_badge';

  final DevtoolConfig config;
  final DevtoolStorage storage;

  final Map<String, bool> _settings = {};
  final Map<String, ChangeNotifier> _toolStates = {};
  bool _ready = false;

  /// True once storage and every tool finished initialising.
  bool get isReady => _ready;

  /// Sections shown on the home screen, in configuration order.
  List<DevtoolSection> get sections => config.sections;

  /// Every tool reachable through a configured section.
  List<DevtoolTool> get tools =>
      [for (final section in sections) ...toolsOf(section)];

  /// Tools of [section]: the ones it ships with, plus the registered tools
  /// pointing at it. A registered tool replaces a built-in with the same id.
  List<DevtoolTool> toolsOf(DevtoolSection section) {
    final configured = sections.firstWhere((candidate) => candidate == section, orElse: () => section);
    final byId = {for (final tool in configured.tools) tool.id: tool};
    for (final tool in DevtoolTools.registered) {
      if (tool.section == section) byId[tool.id] = tool;
    }
    return byId.values.toList(growable: false);
  }

  Future<void> init() async {
    assert(_warnAboutUnreachableTools());
    await storage.load();
    for (final tool in tools) {
      await tool.init(this);
    }
    _ready = true;
    notifyListeners();
  }

  bool _warnAboutUnreachableTools() {
    final configured = sections.map((section) => section.id).toSet();
    for (final tool in DevtoolTools.registered) {
      if (configured.contains(tool.section.id)) continue;
      debugPrint(
        'another_flutter_devtool: tool "${tool.id}" belongs to section '
        '"${tool.section.id}", which is missing from DevtoolConfig.sections.',
      );
    }
    return true;
  }

  /// Seeds a setting from storage, falling back to [defaultValue].
  void registerBoolSetting(String key, {required bool defaultValue}) {
    _settings[key] = storage.getBool(key) ?? defaultValue;
  }

  bool boolSetting(String key, {bool defaultValue = false}) => _settings[key] ?? defaultValue;

  Future<void> setBoolSetting(String key, bool value) async {
    if (_settings[key] == value) return;
    _settings[key] = value;
    notifyListeners();
    await storage.setBool(key, value);
  }

  /// Stores a tool's mutable state, keyed by [DevtoolTool.id].
  void registerToolState(String toolId, ChangeNotifier state) {
    _toolStates.remove(toolId)?.dispose();
    _toolStates[toolId] = state;
  }

  T? toolState<T extends ChangeNotifier>(String toolId) => _toolStates[toolId] as T?;

  /// Lets tool state notify the launcher and the panel of its own changes.
  void refresh() => notifyListeners();

  /// Whether the version label is drawn below the launcher button.
  bool get showVersionBadge => boolSetting(showVersionBadgeKey);

  Future<void> setShowVersionBadge(bool value) => setBoolSetting(showVersionBadgeKey, value);

  @override
  void dispose() {
    for (final tool in tools) {
      tool.dispose();
    }
    for (final state in _toolStates.values) {
      state.dispose();
    }
    _toolStates.clear();
    super.dispose();
  }
}
