import 'dart:convert';
import 'dart:typed_data';

import '../core/http/http_call_observer.dart';

enum NetworkCallState { pending, completed, failed }

/// Buckets used by the status filter chips and status colours.
enum NetworkStatusGroup { pending, informational, success, redirect, clientError, serverError, failed }

/// A captured request or response body.
class NetworkBody {
  const NetworkBody({this.text, this.truncated = false, this.binary = false});

  static const empty = NetworkBody();

  /// Decoded as UTF-8; null when there was no body or it was [binary].
  final String? text;

  /// The body was longer than [NetworkRecorder.maxBodyBytes] and was cut off.
  final bool truncated;

  /// Skipped because the content type is not text (images, video, files)
  final bool binary;
}

/// One HTTP call: request, response and the error if it failed.
class NetworkCall {
  NetworkCall({
    required this.id,
    required this.method,
    required this.uri,
    required this.startedAt,
    this._state = NetworkCallState.pending,
    this._duration,
    this._requestHeaders = const {},
    this._requestBody = NetworkBody.empty,
    this._requestSize = 0,
    this._statusCode,
    this._reasonPhrase,
    this._responseHeaders = const {},
    this._responseBody = NetworkBody.empty,
    this._responseSize = 0,
    this._error,
    this._stackTrace,
  });

  final int id;
  final String method;
  final Uri uri;
  final DateTime startedAt;

  NetworkCallState _state;
  Duration? _duration;
  Map<String, List<String>> _requestHeaders;
  NetworkBody _requestBody;
  int _requestSize;
  int? _statusCode;
  String? _reasonPhrase;
  Map<String, List<String>> _responseHeaders;
  NetworkBody _responseBody;
  int _responseSize;
  Object? _error;
  StackTrace? _stackTrace;

  NetworkCallState get state => _state;
  bool get isPending => _state == NetworkCallState.pending;

  /// Time from opening the request until the response body was fully read.
  Duration? get duration => _duration;

  Map<String, List<String>> get requestHeaders => _requestHeaders;
  NetworkBody get requestBody => _requestBody;

  /// Request body size in bytes, headers excluded.
  int get requestSize => _requestSize;

  int? get statusCode => _statusCode;
  String? get reasonPhrase => _reasonPhrase;
  Map<String, List<String>> get responseHeaders => _responseHeaders;
  NetworkBody get responseBody => _responseBody;

  /// Response body size in bytes, headers excluded.
  int get responseSize => _responseSize;

  Object? get error => _error;
  StackTrace? get stackTrace => _stackTrace;

  Map<String, List<String>> get queryParameters => uri.queryParametersAll;

  NetworkStatusGroup get statusGroup {
    if (_state == NetworkCallState.failed) return NetworkStatusGroup.failed;
    final code = _statusCode;
    if (code == null) return NetworkStatusGroup.pending;
    if (code >= 500) return NetworkStatusGroup.serverError;
    if (code >= 400) return NetworkStatusGroup.clientError;
    if (code >= 300) return NetworkStatusGroup.redirect;
    if (code >= 200) return NetworkStatusGroup.success;
    return NetworkStatusGroup.informational;
  }
}

/// Whether bodies with this content type are skipped instead of decoded.
bool isBinaryContentType(String? contentType) {
  if (contentType == null) return false;
  final type = contentType.toLowerCase();
  const prefixes = ['image/', 'video/', 'audio/', 'font/'];
  const types = ['application/octet-stream', 'application/pdf', 'application/zip', 'application/gzip'];
  return prefixes.any(type.startsWith) || types.any(type.startsWith);
}

/// Fills a [NetworkCall] in as the events of its HTTP call arrive.
class NetworkCallRecording extends HttpCallListener {
  NetworkCallRecording(this.call, {required int maxBodyBytes, required this.onChanged})
      : _request = _BodyBuffer(maxBodyBytes),
        _response = _BodyBuffer(maxBodyBytes);

  final NetworkCall call;
  final void Function() onChanged;
  final _BodyBuffer _request;
  final _BodyBuffer _response;
  final Stopwatch _stopwatch = Stopwatch()..start();
  bool _requestFinished = false;

  @override
  void onRequestHeaders(Map<String, List<String>> headers, int bytes) {
    call._requestHeaders = headers;
    _request.binary = isBinaryContentType(headers['content-type']?.first);
  }

  @override
  void onRequestBody(List<int> chunk) {
    _request.add(chunk);
    call._requestSize = _request.size;
  }

  @override
  void onResponseHeaders(int statusCode, String reasonPhrase, Map<String, List<String>> headers, int bytes) {
    _finishRequest();
    call
      .._statusCode = statusCode
      .._reasonPhrase = reasonPhrase
      .._responseHeaders = headers;
    _response.binary = isBinaryContentType(headers['content-type']?.first);
    onChanged();
  }

  @override
  void onResponseBody(List<int> chunk) {
    _response.add(chunk);
    call._responseSize = _response.size;
  }

  @override
  void onDone() => _finish(NetworkCallState.completed);

  @override
  void onError(Object error, StackTrace stackTrace) {
    call
      .._error = error
      .._stackTrace = stackTrace;
    _finish(NetworkCallState.failed);
  }

  void _finishRequest() {
    if (_requestFinished) return;
    _requestFinished = true;
    call._requestBody = _request.build();
  }

  void _finish(NetworkCallState state) {
    _stopwatch.stop();
    _finishRequest();
    call
      .._responseBody = _response.build()
      .._duration = _stopwatch.elapsed
      .._state = state;
    onChanged();
  }
}

class _BodyBuffer {
  _BodyBuffer(this.maxBytes);

  final int maxBytes;
  final BytesBuilder _bytes = BytesBuilder();
  int size = 0;
  bool binary = false;
  bool truncated = false;

  void add(List<int> chunk) {
    size += chunk.length;
    if (binary || chunk.isEmpty) return;
    final room = maxBytes - _bytes.length;
    if (chunk.length > room) {
      truncated = true;
      if (room > 0) _bytes.add(chunk.sublist(0, room));
    } else {
      _bytes.add(chunk);
    }
  }

  NetworkBody build() => NetworkBody(
        text: binary || _bytes.isEmpty ? null : utf8.decode(_bytes.toBytes(), allowMalformed: true),
        truncated: truncated,
        binary: binary && size > 0,
      );
}
