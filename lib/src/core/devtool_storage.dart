import 'package:shared_preferences/shared_preferences.dart';

/// Key/value storage for devtool settings that survive restarts.
abstract class DevtoolStorage {
  Future<void> load();

  bool? getBool(String key);

  Future<void> setBool(String key, bool value);
}

/// Default storage backed by `shared_preferences`.
class SharedPreferencesDevtoolStorage implements DevtoolStorage {
  SharedPreferences? _prefs;

  @override
  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  bool? getBool(String key) => _prefs?.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async => _prefs?.setBool(key, value);
}

/// Storage that keeps values only for the current session; used by tests.
class InMemoryDevtoolStorage implements DevtoolStorage {
  InMemoryDevtoolStorage([Map<String, Object>? initialValues])
      : _values = {...?initialValues};

  final Map<String, Object> _values;

  @override
  Future<void> load() async {}

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;
}
