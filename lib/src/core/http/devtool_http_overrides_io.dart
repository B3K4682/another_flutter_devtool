import 'dart:io';

import 'http_call_observer.dart';
import 'observing_http_client.dart';

/// Wraps every new HttpClient so its calls reach [DevtoolHttp.observers].
bool installDevtoolHttpOverrides() {
  final current = HttpOverrides.current;
  if (current is DevtoolHttpOverrides) return true;
  HttpOverrides.global = DevtoolHttpOverrides(previous: current);
  return true;
}

/// Chains [previous] so overrides installed by the app keep working.
class DevtoolHttpOverrides extends HttpOverrides {
  /// Uses [observers] when given, otherwise the live [DevtoolHttp.observers].
  DevtoolHttpOverrides({this.previous, this._observers});

  final HttpOverrides? previous;
  final List<HttpCallObserver>? _observers;

  List<HttpCallObserver> get observers => _observers ?? DevtoolHttp.observers;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final inner = previous?.createHttpClient(context) ?? super.createHttpClient(context);
    return ObservingHttpClient(inner, () => observers);
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) =>
      previous?.findProxyFromEnvironment(url, environment) ?? super.findProxyFromEnvironment(url, environment);
}
