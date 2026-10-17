import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'network_usage_tracker.dart';

// ! Bottleneck: reImplementing HttpClient and needs updating when HttpClient changes.

/// HttpClient that reports request and response sizes to a [NetworkUsageTracker].
class TrackingHttpClient implements HttpClient {
  TrackingHttpClient(this._inner, this._tracker);

  final HttpClient _inner;
  final NetworkUsageTracker _tracker;

  Future<HttpClientRequest> _track(Future<HttpClientRequest> request) =>
      request.then((inner) => _TrackingRequest(inner, _tracker));

  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _inner.userAgent;
  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) =>
      _inner.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) =>
      _inner.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) => _inner.authenticate = f;

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) =>
      _inner.authenticateProxy = f;

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) =>
      _inner.badCertificateCallback = callback;

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) =>
      _inner.connectionFactory = f;

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) =>
      _track(_inner.open(method, host, port, path));

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _track(_inner.openUrl(method, url));

  @override
  Future<HttpClientRequest> get(String host, int port, String path) => _track(_inner.get(host, port, path));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _track(_inner.getUrl(url));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) => _track(_inner.post(host, port, path));

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _track(_inner.postUrl(url));

  @override
  Future<HttpClientRequest> put(String host, int port, String path) => _track(_inner.put(host, port, path));

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _track(_inner.putUrl(url));

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => _track(_inner.delete(host, port, path));

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _track(_inner.deleteUrl(url));

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => _track(_inner.patch(host, port, path));

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _track(_inner.patchUrl(url));

  @override
  Future<HttpClientRequest> head(String host, int port, String path) => _track(_inner.head(host, port, path));

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _track(_inner.headUrl(url));
}

class _TrackingRequest implements HttpClientRequest {
  _TrackingRequest(this._inner, this._tracker) : _host = _inner.uri.host {
    _tracker.recordRequest(_host);
  }

  final HttpClientRequest _inner;
  final NetworkUsageTracker _tracker;
  final String _host;
  late final Future<HttpClientResponse> _done = _inner.done.then(
    (response) => _TrackingResponse(response, _tracker, _host),
  );
  bool _headersCounted = false;

  void _countHeaders() {
    if (_headersCounted) return;
    _headersCounted = true;
    final requestLine = '${_inner.method} ${_inner.uri} HTTP/1.1\r\n';
    _tracker.recordSent(_host, requestLine.length + _inner.headers.toString().length + 2);
  }

  void _countBody(List<int> data) => _tracker.recordSent(_host, data.length);

  @override
  bool get bufferOutput => _inner.bufferOutput;
  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;

  @override
  int get contentLength => _inner.contentLength;
  @override
  set contentLength(int value) => _inner.contentLength = value;

  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;

  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;

  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  String get method => _inner.method;

  @override
  Uri get uri => _inner.uri;

  @override
  Future<HttpClientResponse> get done => _done;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) => _inner.abort(exception, stackTrace);

  @override
  void add(List<int> data) {
    _countHeaders();
    _countBody(data);
    _inner.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _inner.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    _countHeaders();
    return _inner.addStream(stream.map((chunk) {
      _countBody(chunk);
      return chunk;
    }));
  }

  @override
  Future<HttpClientResponse> close() {
    _countHeaders();
    final done = _done;
    _inner.close().ignore();
    return done;
  }

  @override
  Future<void> flush() => _inner.flush();

  @override
  void write(Object? object) {
    final string = '$object';
    if (string.isEmpty) return;
    add(encoding.encode(string));
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) => write(objects.join(separator));

  @override
  void writeCharCode(int charCode) => write(String.fromCharCode(charCode));

  @override
  void writeln([Object? object = '']) => write('$object\n');
}

class _TrackingResponse extends StreamView<List<int>> implements HttpClientResponse {
  _TrackingResponse(this._inner, NetworkUsageTracker tracker, String host)
      : super(_inner.map((chunk) {
          tracker.recordReceived(host, chunk.length);
          return chunk;
        })) {
    final statusLine = 'HTTP/1.1 ${_inner.statusCode} ${_inner.reasonPhrase}\r\n';
    tracker.recordReceived(host, statusLine.length + _inner.headers.toString().length + 2);
  }

  final HttpClientResponse _inner;

  @override
  X509Certificate? get certificate => _inner.certificate;

  @override
  HttpClientResponseCompressionState get compressionState => _inner.compressionState;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  int get contentLength => _inner.contentLength;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  bool get isRedirect => _inner.isRedirect;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  List<RedirectInfo> get redirects => _inner.redirects;

  @override
  int get statusCode => _inner.statusCode;

  @override
  Future<Socket> detachSocket() => _inner.detachSocket();

  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) =>
      _inner.redirect(method, url, followLoops);
}
