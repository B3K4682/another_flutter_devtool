/// Header names (lowercase) whose values are masked on screen and in JSON exports.
const defaultRedactedHeaders = {
  'authorization',
  'proxy-authorization',
  'cookie',
  'set-cookie',
  'x-api-key',
  'x-auth-token',
  'x-access-token',
  'x-refresh-token',
  'x-csrf-token',
  'x-xsrf-token',
  'x-amz-security-token',
};

/// Query parameter names (lowercase) whose values are masked on screen and in JSON exports.
const defaultRedactedQueryParameters = {
  'access_token',
  'refresh_token',
  'id_token',
  'token',
  'api_key',
  'apikey',
  'client_secret',
  'password',
  'signature',
  'sig',
  'x-amz-signature',
  'x-amz-credential',
  'x-amz-security-token',
};

/// Shown in place of a masked value.
const redactedValue = '[redacted]';

/// Whether [name] is in [redacted], ignoring case.
bool isRedacted(String name, Set<String> redacted) => redacted.contains(name.toLowerCase());

/// [values] with every value of a [redacted] name replaced by [redactedValue].
Map<String, List<String>> redactValues(Map<String, List<String>> values, Set<String> redacted) => {
  for (final entry in values.entries) entry.key: isRedacted(entry.key, redacted) ? const [redactedValue] : entry.value,
};

/// [uri] as text with the values of [redacted] query parameters masked.
String redactUrl(Uri uri, Set<String> redacted) {
  final text = uri.toString();
  if (!uri.hasQuery || !uri.queryParametersAll.keys.any((name) => isRedacted(name, redacted))) return text;
  final query = uri.query
      .split('&')
      .map((part) {
        final separator = part.indexOf('=');
        final name = separator == -1 ? part : part.substring(0, separator);
        return isRedacted(Uri.decodeQueryComponent(name), redacted) ? '$name=$redactedValue' : part;
      })
      .join('&');
  return text.replaceFirst('?${uri.query}', '?$query');
}
