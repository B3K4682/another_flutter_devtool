import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'http_call_observer.dart';

// ! Bottleneck: reImplementing HttpClient and needs updating when HttpClient changes.

/// HttpClient that reports every call to the current [HttpCallObserver]s.
class ObservingHttpClient implements HttpClient {
  ObservingHttpClient(this._inner, this._observers);

  final HttpClient _inner;
  final List<HttpCallObserver> Function() _observers;

  Future<HttpClientRequest> _observe(String method, Uri uri, Future<HttpClientRequest> request) {
    final events = _CallEvents([for (final observer in _observers()) ?observer.onCall(method, uri)]);
    return request.then(
      (inner) => _ObservingRequest(inner, events),
      onError: (Object error, StackTrace stackTrace) {
        events.error(error, stackTrace);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  static Uri _uri(String host, int port, String path) {
    final query = path.indexOf('?');
    return Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: query == -1 ? path : path.substring(0, query),
      query: query == -1 ? null : path.substring(query + 1),
    );
  }

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
      _observe(method, _uri(host, port, path), _inner.open(method, host, port, path));

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _observe(method, url, _inner.openUrl(method, url));

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _observe('GET', _uri(host, port, path), _inner.get(host, port, path));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _observe('GET', url, _inner.getUrl(url));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _observe('POST', _uri(host, port, path), _inner.post(host, port, path));

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _observe('POST', url, _inner.postUrl(url));

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _observe('PUT', _uri(host, port, path), _inner.put(host, port, path));

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _observe('PUT', url, _inner.putUrl(url));

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _observe('DELETE', _uri(host, port, path), _inner.delete(host, port, path));

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _observe('DELETE', url, _inner.deleteUrl(url));

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _observe('PATCH', _uri(host, port, path), _inner.patch(host, port, path));

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _observe('PATCH', url, _inner.patchUrl(url));

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _observe('HEAD', _uri(host, port, path), _inner.head(host, port, path));

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _observe('HEAD', url, _inner.headUrl(url));
}

/// Fans one call's events out to every listener; finishes at most once.
class _CallEvents {
  _CallEvents(this._listeners);

  final List<HttpCallListener> _listeners;
  bool _finished = false;

  bool get isEmpty => _listeners.isEmpty;

  void requestHeaders(Map<String, List<String>> headers, int bytes) {
    for (final listener in _listeners) {
      listener.onRequestHeaders(headers, bytes);
    }
  }

  void requestBody(List<int> chunk) {
    for (final listener in _listeners) {
      listener.onRequestBody(chunk);
    }
  }

  void responseHeaders(int statusCode, String reasonPhrase, Map<String, List<String>> headers, int bytes) {
    for (final listener in _listeners) {
      listener.onResponseHeaders(statusCode, reasonPhrase, headers, bytes);
    }
  }

  void responseBody(List<int> chunk) {
    for (final listener in _listeners) {
      listener.onResponseBody(chunk);
    }
  }

  void done() {
    if (_finished) return;
    _finished = true;
    for (final listener in _listeners) {
      listener.onDone();
    }
  }

  void error(Object error, StackTrace stackTrace) {
    if (_finished) return;
    _finished = true;
    for (final listener in _listeners) {
      listener.onError(error, stackTrace);
    }
  }
}

Map<String, List<String>> _headersMap(HttpHeaders headers) {
  final map = <String, List<String>>{};
  headers.forEach((name, values) => map[name] = List.unmodifiable(values));
  return map;
}

class _ObservingRequest implements HttpClientRequest {
  _ObservingRequest(this._inner, this._events);

  final HttpClientRequest _inner;
  final _CallEvents _events;
  late final Future<HttpClientResponse> _done = _inner.done.then(
    (response) => _ObservingResponse(response, _events),
    onError: (Object error, StackTrace stackTrace) {
      _events.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    },
  );
  bool _headersSent = false;

  void _sendHeaders() {
    if (_headersSent) return;
    _headersSent = true;
    if (_events.isEmpty) return;
    final requestLine = '${_inner.method} ${_inner.uri} HTTP/1.1\r\n';
    _events.requestHeaders(_headersMap(_inner.headers), requestLine.length + _inner.headers.toString().length + 2);
  }

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
    _sendHeaders();
    _events.requestBody(data);
    _inner.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _inner.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    _sendHeaders();
    return _inner.addStream(
      stream.map((chunk) {
        _events.requestBody(chunk);
        return chunk;
      }),
    );
  }

  @override
  Future<HttpClientResponse> close() {
    _sendHeaders();
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

class _ObservingResponse extends StreamView<List<int>> implements HttpClientResponse {
  _ObservingResponse(this._inner, _CallEvents events)
    : super(
        _inner.transform(
          StreamTransformer.fromHandlers(
            handleData: (chunk, sink) {
              events.responseBody(chunk);
              sink.add(chunk);
            },
            handleError: (error, stackTrace, sink) {
              events.error(error, stackTrace);
              sink.addError(error, stackTrace);
            },
            handleDone: (sink) {
              events.done();
              sink.close();
            },
          ),
        ),
      ) {
    if (events.isEmpty) return;
    final statusLine = 'HTTP/1.1 ${_inner.statusCode} ${_inner.reasonPhrase}\r\n';
    events.responseHeaders(
      _inner.statusCode,
      _inner.reasonPhrase,
      _headersMap(_inner.headers),
      statusLine.length + _inner.headers.toString().length + 2,
    );
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
