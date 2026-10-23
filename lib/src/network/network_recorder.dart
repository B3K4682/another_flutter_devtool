import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/http/http_call_observer.dart';
import 'network_call.dart';

/// Records HTTP calls made through dart:io's HttpClient (Dio, http, images).
class NetworkRecorder extends ChangeNotifier implements HttpCallObserver {
  NetworkRecorder({
    this.maxCalls = 500,
    this.maxBodyBytes = 256 * 1024,
    this.notifyInterval = const Duration(milliseconds: 250),
  });

  /// Shared recorder used by [NetworkSection] by default.
  static final instance = NetworkRecorder();

  /// Oldest calls are dropped once this many are kept.
  final int maxCalls;

  /// Bodies longer than this are cut off and marked truncated.
  final int maxBodyBytes;

  /// Minimum gap between listener notifications while traffic is flowing.
  final Duration notifyInterval;

  final List<NetworkCall> _calls = [];
  int _nextId = 1;
  bool _paused = false;
  bool _installed = false;
  Timer? _notifyTimer;

  /// Whether the HttpOverrides hook is active.
  bool get isInstalled => _installed;

  /// While paused, new calls are not recorded.
  bool get isPaused => _paused;

  /// Newest first.
  List<NetworkCall> get calls => _calls.reversed.toList(growable: false);

  /// Hooks into HttpOverrides.global; safe to call more than once.
  void install() {
    if (_installed) return;
    _installed = DevtoolHttp.install(this);
  }

  void setPaused(bool value) {
    if (_paused == value) return;
    _paused = value;
    _notifyNow();
  }

  @override
  HttpCallListener? onCall(String method, Uri uri) {
    if (_paused) return null;
    final call = NetworkCall(id: _nextId++, method: method.toUpperCase(), uri: uri, startedAt: DateTime.now());
    add(call);
    return NetworkCallRecording(call, maxBodyBytes: maxBodyBytes, onChanged: _scheduleNotify);
  }

  /// Adds an already built call, for example one logged by hand.
  void add(NetworkCall call) {
    _calls.add(call);
    if (call.id >= _nextId) _nextId = call.id + 1;
    _trim();
    _scheduleNotify();
  }

  NetworkCall? byId(int id) {
    for (final call in _calls) {
      if (call.id == id) return call;
    }
    return null;
  }

  /// Removes every call and returns them, newest first, so they can be restored.
  List<NetworkCall> clear() {
    final removed = calls;
    _calls.clear();
    _notifyNow();
    return removed;
  }

  /// Puts back calls removed by [clear], keeping calls recorded since.
  void restore(Iterable<NetworkCall> calls) {
    final ids = {for (final call in _calls) call.id};
    _calls
      ..addAll(calls.where((call) => !ids.contains(call.id)))
      ..sort((a, b) => a.id.compareTo(b.id));
    _trim();
    _notifyNow();
  }

  void _trim() {
    if (_calls.length > maxCalls) _calls.removeRange(0, _calls.length - maxCalls);
  }

  void _scheduleNotify() {
    _notifyTimer ??= Timer(notifyInterval, () {
      _notifyTimer = null;
      notifyListeners();
    });
  }

  void _notifyNow() {
    _notifyTimer?.cancel();
    _notifyTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    DevtoolHttp.uninstall(this);
    super.dispose();
  }
}
