import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../keys.dart';
import '../theme/devtool_theme.dart';
import '../tools/network_usage/byte_format.dart';
import 'network_call.dart';
import 'network_export.dart';
import 'network_format.dart';
import 'network_recorder.dart';
import 'network_redaction.dart';
import 'network_share.dart';
import 'network_status_pill.dart';

/// Request, response and error of a single [NetworkCall]; updates live while pending.
/// Sensitive headers and query parameters are masked until revealed from the app bar.
class NetworkCallDetailsPage extends StatefulWidget {
  const NetworkCallDetailsPage({
    super.key,
    required this.recorder,
    required this.call,
    this.redactedHeaders = defaultRedactedHeaders,
    this.redactedQueryParameters = defaultRedactedQueryParameters,
  });

  final NetworkRecorder recorder;
  final NetworkCall call;
  final Set<String> redactedHeaders;
  final Set<String> redactedQueryParameters;

  @override
  State<NetworkCallDetailsPage> createState() => _NetworkCallDetailsPageState();
}

class _NetworkCallDetailsPageState extends State<NetworkCallDetailsPage> {
  bool _revealed = false;

  NetworkCall get call => widget.call;

  bool get _hasSecrets =>
      call.queryParameters.keys.any((name) => isRedacted(name, widget.redactedQueryParameters)) ||
      call.requestHeaders.keys.any((name) => isRedacted(name, widget.redactedHeaders)) ||
      call.responseHeaders.keys.any((name) => isRedacted(name, widget.redactedHeaders));

  Map<String, List<String>> _headers(Map<String, List<String>> headers) =>
      _revealed ? headers : redactValues(headers, widget.redactedHeaders);

  Future<void> _copyCurl(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: toCurl(call)));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('cURL copied')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.recorder,
      builder: (context, _) {
        final hasError = call.error != null;
        final tabCount = hasError ? 3 : 2;
        final hasSecrets = _hasSecrets;
        final query = _revealed
            ? call.queryParameters
            : redactValues(call.queryParameters, widget.redactedQueryParameters);
        final url = _revealed ? call.uri.toString() : redactUrl(call.uri, widget.redactedQueryParameters);

        return DefaultTabController(
          key: ValueKey(tabCount),
          length: tabCount,
          initialIndex: hasError && call.statusCode == null ? 2 : 0,
          child: Scaffold(
            key: DevtoolKeys.networkCallDetails,
            appBar: AppBar(
              title: const Text('Call'),
              actions: [
                if (hasSecrets)
                  IconButton(
                    key: DevtoolKeys.networkRevealSecretsButton,
                    tooltip: _revealed ? 'Hide sensitive values' : 'Show sensitive values',
                    isSelected: _revealed,
                    icon: const Icon(Icons.visibility_off_outlined, size: 20),
                    selectedIcon: const Icon(Icons.visibility_outlined, size: 20, color: DevtoolColors.warning),
                    onPressed: () => setState(() => _revealed = !_revealed),
                  ),
                IconButton(
                  key: DevtoolKeys.networkCopyCurlButton,
                  tooltip: 'Copy as cURL',
                  icon: const Icon(Icons.terminal_rounded, size: 20),
                  onPressed: () => _copyCurl(context),
                ),
                Builder(
                  builder: (buttonContext) => IconButton(
                    key: DevtoolKeys.networkExportCallButton,
                    tooltip: 'Export JSON',
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    onPressed: () => shareJson(
                      buttonContext,
                      json: exportCallJson(
                        call,
                        redactedHeaders: widget.redactedHeaders,
                        redactedQueryParameters: widget.redactedQueryParameters,
                      ),
                      fileName: callFileName(call),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Summary(call: call, url: url),
                TabBar(
                  tabs: [
                    const Tab(text: 'Request', height: 42),
                    const Tab(text: 'Response', height: 42),
                    if (hasError)
                      const Tab(
                        height: 42,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error'),
                            SizedBox(width: 6),
                            _Dot(color: DevtoolColors.error),
                          ],
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _RequestTab(
                        call: call,
                        query: query,
                        headers: _headers(call.requestHeaders),
                        maxBodyBytes: widget.recorder.maxBodyBytes,
                      ),
                      _ResponseTab(
                        call: call,
                        headers: _headers(call.responseHeaders),
                        maxBodyBytes: widget.recorder.maxBodyBytes,
                      ),
                      if (hasError) _ErrorTab(call: call),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.call, required this.url});

  final NetworkCall call;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = call.duration;
    final meta = [
      formatTime(call.startedAt),
      'Sent ${formatBytes(call.requestSize)}',
      'Received ${formatBytes(call.responseSize)}',
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(DevtoolSpacing.padding, 4, DevtoolSpacing.padding, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NetworkStatusPill(call: call),
              const SizedBox(width: 10),
              Text(call.method, style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(
                duration == null ? 'Pending' : formatDuration(duration),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DevtoolColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(url, style: monoStyle.copyWith(fontSize: 13)),
          const SizedBox(height: 8),
          Text(meta, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  const _RequestTab({required this.call, required this.query, required this.headers, required this.maxBodyBytes});

  final NetworkCall call;
  final Map<String, List<String>> query;
  final Map<String, List<String>> headers;
  final int maxBodyBytes;

  @override
  Widget build(BuildContext context) {
    return _TabList(
      children: [
        if (query.isNotEmpty)
          _Block(
            label: 'Query parameters',
            child: _KeyValueTable(entries: query),
          ),
        _Block(
          label: 'Headers',
          child: _KeyValueTable(entries: headers),
        ),
        _Block(
          label: 'Body',
          child: _BodyView(body: call.requestBody, size: call.requestSize, maxBodyBytes: maxBodyBytes),
        ),
      ],
    );
  }
}

class _ResponseTab extends StatelessWidget {
  const _ResponseTab({required this.call, required this.headers, required this.maxBodyBytes});

  final NetworkCall call;
  final Map<String, List<String>> headers;
  final int maxBodyBytes;

  @override
  Widget build(BuildContext context) {
    final code = call.statusCode;
    if (code == null) {
      return _Placeholder(text: call.isPending ? 'Waiting for response' : 'No response received');
    }

    return _TabList(
      children: [
        _Block(
          label: 'Status',
          child: _Panel(
            child: Text(
              [code, call.reasonPhrase].whereType<Object>().join(' '),
              style: monoStyle.copyWith(color: statusColor(call.statusGroup), fontWeight: FontWeight.w600),
            ),
          ),
        ),
        _Block(
          label: 'Headers',
          child: _KeyValueTable(entries: headers),
        ),
        _Block(
          label: 'Body',
          child: call.isPending && call.responseBody.text == null
              ? const _Panel(child: _Muted('Receiving'))
              : _BodyView(body: call.responseBody, size: call.responseSize, maxBodyBytes: maxBodyBytes),
        ),
      ],
    );
  }
}

class _ErrorTab extends StatelessWidget {
  const _ErrorTab({required this.call});

  final NetworkCall call;

  @override
  Widget build(BuildContext context) {
    final stackTrace = call.stackTrace?.toString().trim() ?? '';

    return _TabList(
      children: [
        _Block(
          label: 'Error',
          child: _Panel(
            child: SelectableText('${call.error}', style: monoStyle.copyWith(color: DevtoolColors.error)),
          ),
        ),
        if (stackTrace.isNotEmpty)
          _Block(
            label: 'Stack trace',
            child: _Panel(child: SelectableText(stackTrace, style: monoStyle.copyWith(fontSize: 11))),
          ),
      ],
    );
  }
}

class _TabList extends StatelessWidget {
  const _TabList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(DevtoolSpacing.padding),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (_, index) => children[index],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        ),
        child,
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(12)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DevtoolColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DevtoolColors.border),
      ),
      child: child,
    );
  }
}

class _KeyValueTable extends StatelessWidget {
  const _KeyValueTable({required this.entries});

  final Map<String, List<String>> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const _Panel(child: _Muted('None'));
    final rows = [
      for (final entry in entries.entries)
        for (final value in entry.value) (entry.key, value),
    ];

    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SelectableText(
                      rows[index].$1,
                      style: monoStyle.copyWith(color: DevtoolColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: SelectableText(
                      rows[index].$2,
                      style: rows[index].$2 == redactedValue
                          ? monoStyle.copyWith(color: DevtoolColors.textSecondary)
                          : monoStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BodyView extends StatelessWidget {
  const _BodyView({required this.body, required this.size, required this.maxBodyBytes});

  final NetworkBody body;
  final int size;
  final int maxBodyBytes;

  @override
  Widget build(BuildContext context) {
    final text = body.text;
    if (body.binary) return _Panel(child: _Muted('Binary content, ${formatBytes(size)}, not captured'));
    if (text == null || text.isEmpty) return const _Panel(child: _Muted('No body'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(child: SelectableText(body.truncated ? text : prettyBody(text), style: monoStyle)),
        if (body.truncated)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Showing the first ${formatBytes(maxBodyBytes)} of ${formatBytes(size)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DevtoolColors.warning),
            ),
          ),
      ],
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.bodySmall);
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(child: _Muted(text));
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
