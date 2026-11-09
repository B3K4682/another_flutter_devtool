import 'dart:convert';

import 'network_call.dart';
import 'network_redaction.dart';

const _encoder = JsonEncoder.withIndent('  ');

/// Every call in [calls] as pretty-printed JSON.
String exportCallsJson(
  Iterable<NetworkCall> calls, {
  Set<String> redactedHeaders = defaultRedactedHeaders,
  Set<String> redactedQueryParameters = defaultRedactedQueryParameters,
  DateTime? exportedAt,
}) {
  final list = [
    for (final call in calls)
      networkCallToJson(call, redactedHeaders: redactedHeaders, redactedQueryParameters: redactedQueryParameters),
  ];
  return _encoder.convert({
    'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
    'count': list.length,
    'calls': list,
  });
}

/// A single call as pretty-printed JSON.
String exportCallJson(
  NetworkCall call, {
  Set<String> redactedHeaders = defaultRedactedHeaders,
  Set<String> redactedQueryParameters = defaultRedactedQueryParameters,
}) => _encoder.convert(
  networkCallToJson(call, redactedHeaders: redactedHeaders, redactedQueryParameters: redactedQueryParameters),
);

Map<String, Object?> networkCallToJson(
  NetworkCall call, {
  Set<String> redactedHeaders = defaultRedactedHeaders,
  Set<String> redactedQueryParameters = defaultRedactedQueryParameters,
}) {
  final error = call.error;
  return {
    'id': call.id,
    'method': call.method,
    'url': redactUrl(call.uri, redactedQueryParameters),
    'state': call.state.name,
    'status': call.statusCode,
    'reasonPhrase': call.reasonPhrase,
    'startedAt': call.startedAt.toIso8601String(),
    'durationMs': call.duration?.inMilliseconds,
    'request': {
      'query': _valuesToJson(redactValues(call.queryParameters, redactedQueryParameters)),
      'headers': _valuesToJson(redactValues(call.requestHeaders, redactedHeaders)),
      'size': call.requestSize,
      'body': _bodyToJson(call.requestBody),
      'bodyTruncated': call.requestBody.truncated,
      'bodyBinary': call.requestBody.binary,
    },
    'response': {
      'headers': _valuesToJson(redactValues(call.responseHeaders, redactedHeaders)),
      'size': call.responseSize,
      'body': _bodyToJson(call.responseBody),
      'bodyTruncated': call.responseBody.truncated,
      'bodyBinary': call.responseBody.binary,
    },
    'error': error == null ? null : {'message': '$error', 'stackTrace': call.stackTrace?.toString()},
  };
}

Map<String, Object> _valuesToJson(Map<String, List<String>> values) => {
  for (final entry in values.entries) entry.key: entry.value.length == 1 ? entry.value.single : entry.value,
};

/// Embeds JSON bodies as JSON, everything else as a string.
Object? _bodyToJson(NetworkBody body) {
  final text = body.text;
  if (text == null || body.truncated) return text;
  return tryDecodeJson(text) ?? text;
}

/// Parsed JSON when [text] is a JSON object or array, otherwise null.
Object? tryDecodeJson(String text) {
  final trimmed = text.trimLeft();
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return null;
  try {
    return jsonDecode(trimmed);
  } on FormatException {
    return null;
  }
}

/// [text] re-indented when it is JSON, otherwise unchanged.
String prettyBody(String text) {
  final decoded = tryDecodeJson(text);
  return decoded == null ? text : _encoder.convert(decoded);
}

/// A cURL command that replays [call]; nothing is redacted.
String toCurl(NetworkCall call) {
  const skipped = {'content-length', 'host'};
  final parts = <String>['curl'];
  if (call.method != 'GET') parts.add('-X ${call.method}');
  parts.add(_quote(call.uri.toString()));
  for (final entry in call.requestHeaders.entries) {
    if (skipped.contains(entry.key.toLowerCase())) continue;
    for (final value in entry.value) {
      parts.add('-H ${_quote('${entry.key}: $value')}');
    }
  }
  final body = call.requestBody.text;
  if (body != null && body.isNotEmpty) parts.add('--data-raw ${_quote(body)}');
  return parts.join(' \\\n  ');
}

String _quote(String value) => "'${value.replaceAll("'", r"'\''")}'";
