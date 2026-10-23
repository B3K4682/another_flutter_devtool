import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/http/http_call_observer.dart';
import 'network_usage_stats.dart';

/// Counts HTTP traffic made through dart:io's HttpClient (Dio, http, images).
class NetworkUsageTracker extends ChangeNotifier implements HttpCallObserver {
  NetworkUsageTracker({this.notifyInterval = const Duration(milliseconds: 500)});

  /// Shared tracker used by [NetworkUsageTool] by default.
  static final instance = NetworkUsageTracker();

  /// Minimum gap between listener notifications while traffic is flowing.
  final Duration notifyInterval;

  final Map<String, _HostCounter> _hosts = {};
  int _received = 0;
  int _sent = 0;
  int _requests = 0;
  bool _installed = false;
  Timer? _notifyTimer;

  /// Whether the HttpOverrides hook is active.
  bool get isInstalled => _installed;

  NetworkUsageStats get stats => NetworkUsageStats(
        bytesReceived: _received,
        bytesSent: _sent,
        requestCount: _requests,
        hosts: {
          for (final entry in _hosts.entries)
            entry.key: HostUsage(
              host: entry.key,
              bytesReceived: entry.value.received,
              bytesSent: entry.value.sent,
              requests: entry.value.requests,
            ),
        },
      );

  /// Hooks into HttpOverrides.global; safe to call more than once.
  void install() {
    if (_installed) return;
    _installed = DevtoolHttp.install(this);
  }

  @override
  HttpCallListener onCall(String method, Uri uri) {
    recordRequest(uri.host);
    return _UsageListener(this, uri.host);
  }

  void recordRequest(String host) {
    _requests++;
    _host(host).requests++;
    _scheduleNotify();
  }

  void recordSent(String host, int bytes) {
    if (bytes <= 0) return;
    _sent += bytes;
    _host(host).sent += bytes;
    _scheduleNotify();
  }

  void recordReceived(String host, int bytes) {
    if (bytes <= 0) return;
    _received += bytes;
    _host(host).received += bytes;
    _scheduleNotify();
  }

  void reset() {
    _hosts.clear();
    _received = 0;
    _sent = 0;
    _requests = 0;
    _notifyTimer?.cancel();
    _notifyTimer = null;
    notifyListeners();
  }

  _HostCounter _host(String host) => _hosts.putIfAbsent(host, _HostCounter.new);

  void _scheduleNotify() {
    _notifyTimer ??= Timer(notifyInterval, () {
      _notifyTimer = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    super.dispose();
  }
}

class _UsageListener extends HttpCallListener {
  _UsageListener(this._tracker, this._host);

  final NetworkUsageTracker _tracker;
  final String _host;

  @override
  void onRequestHeaders(Map<String, List<String>> headers, int bytes) => _tracker.recordSent(_host, bytes);

  @override
  void onRequestBody(List<int> chunk) => _tracker.recordSent(_host, chunk.length);

  @override
  void onResponseHeaders(int statusCode, String reasonPhrase, Map<String, List<String>> headers, int bytes) =>
      _tracker.recordReceived(_host, bytes);

  @override
  void onResponseBody(List<int> chunk) => _tracker.recordReceived(_host, chunk.length);
}

class _HostCounter {
  int received = 0;
  int sent = 0;
  int requests = 0;
}
