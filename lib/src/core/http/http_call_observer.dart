import 'devtool_http_overrides.dart';

/// Gets notified of every HTTP call made through dart:io's HttpClient.
abstract interface class HttpCallObserver {
  /// Returns a listener for this call, or null to ignore it.
  HttpCallListener? onCall(String method, Uri uri);
}

/// Receives the events of a single HTTP call, in order.
abstract class HttpCallListener {
  /// [bytes] approximates the request line plus headers on the wire.
  void onRequestHeaders(Map<String, List<String>> headers, int bytes) {}

  void onRequestBody(List<int> chunk) {}

  /// [bytes] approximates the status line plus headers on the wire.
  void onResponseHeaders(int statusCode, String reasonPhrase, Map<String, List<String>> headers, int bytes) {}

  void onResponseBody(List<int> chunk) {}

  void onDone() {}

  void onError(Object error, StackTrace stackTrace) {}
}

/// Process-wide list of observers fed by [DevtoolHttpOverrides].
abstract final class DevtoolHttp {
  static final List<HttpCallObserver> _observers = [];

  static List<HttpCallObserver> get observers => List.unmodifiable(_observers);

  /// Adds [observer] and hooks HttpOverrides.global; false when unsupported (web).
  static bool install(HttpCallObserver observer) {
    if (!_observers.contains(observer)) _observers.add(observer);
    return installDevtoolHttpOverrides();
  }

  static void uninstall(HttpCallObserver observer) => _observers.remove(observer);
}
