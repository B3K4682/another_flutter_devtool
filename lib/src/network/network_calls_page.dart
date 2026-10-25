import 'package:flutter/material.dart';

import '../keys.dart';
import '../theme/devtool_theme.dart';
import 'network_call.dart';
import 'network_call_details_page.dart';
import 'network_export.dart';
import 'network_format.dart';
import 'network_recorder.dart';
import 'network_share.dart';
import 'network_status_pill.dart';

enum _StatusFilter {
  all('all', 'All', null),
  success('2xx', '2xx', NetworkStatusGroup.success),
  redirect('3xx', '3xx', NetworkStatusGroup.redirect),
  clientError('4xx', '4xx', NetworkStatusGroup.clientError),
  serverError('5xx', '5xx', NetworkStatusGroup.serverError),
  failed('failed', 'Failed', NetworkStatusGroup.failed);

  const _StatusFilter(this.id, this.label, this.group);

  final String id;
  final String label;
  final NetworkStatusGroup? group;

  bool matches(NetworkCall call) => group == null || call.statusGroup == group;
}

/// Every recorded call, newest first, with search and status filters.
class NetworkCallsPage extends StatefulWidget {
  const NetworkCallsPage({super.key, required this.recorder, this.redactedHeaders = defaultRedactedHeaders});

  final NetworkRecorder recorder;
  final Set<String> redactedHeaders;

  @override
  State<NetworkCallsPage> createState() => _NetworkCallsPageState();
}

class _NetworkCallsPageState extends State<NetworkCallsPage> {
  final _searchController = TextEditingController();
  _StatusFilter _filter = _StatusFilter.all;

  NetworkRecorder get _recorder => widget.recorder;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(NetworkCall call) {
    final terms = _searchController.text.toLowerCase().split(RegExp(r'\s+')).where((term) => term.isNotEmpty);
    if (terms.isEmpty) return true;
    final haystack = '${call.method} ${call.statusCode ?? ''} ${call.uri}'.toLowerCase();
    return terms.every(haystack.contains);
  }

  void _clear() {
    final removed = _recorder.clear();
    if (removed.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Cleared ${_countLabel(removed.length)}'),
          action: SnackBarAction(label: 'Undo', onPressed: () => _recorder.restore(removed)),
        ),
      );
  }

  Future<void> _export(BuildContext buttonContext) => shareJson(
    buttonContext,
    json: exportCallsJson(_recorder.calls, redactedHeaders: widget.redactedHeaders),
    fileName: callsFileName(DateTime.now()),
  );

  void _open(NetworkCall call) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NetworkCallDetailsPage(recorder: _recorder, call: call, redactedHeaders: widget.redactedHeaders),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _recorder,
      builder: (context, _) {
        final calls = _recorder.calls;
        final searched = calls.where(_matchesSearch).toList(growable: false);
        final visible = searched.where(_filter.matches).toList(growable: false);
        final filtering = visible.length != calls.length;

        return Scaffold(
          key: DevtoolKeys.networkCallsPage,
          appBar: AppBar(
            title: const Text('Network'),
            actions: [
              IconButton(
                key: DevtoolKeys.networkPauseButton,
                tooltip: _recorder.isPaused ? 'Resume recording' : 'Pause recording',
                icon: Icon(_recorder.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                onPressed: () => _recorder.setPaused(!_recorder.isPaused),
              ),
              Builder(
                builder: (buttonContext) => IconButton(
                  key: DevtoolKeys.networkExportButton,
                  tooltip: 'Export JSON',
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  onPressed: calls.isEmpty ? null : () => _export(buttonContext),
                ),
              ),
              IconButton(
                key: DevtoolKeys.networkClearButton,
                tooltip: 'Clear',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: calls.isEmpty ? null : _clear,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(DevtoolSpacing.padding, 4, DevtoolSpacing.padding, 10),
                child: _SearchField(controller: _searchController),
              ),
              _FilterBar(
                selected: _filter,
                counts: {for (final filter in _StatusFilter.values) filter: searched.where(filter.matches).length},
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(DevtoolSpacing.padding, 12, DevtoolSpacing.padding, 8),
                child: Row(
                  children: [
                    Text(
                      filtering ? '${visible.length} of ${_countLabel(calls.length)}' : _countLabel(calls.length),
                      key: DevtoolKeys.networkCallCount,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    if (_recorder.isPaused) const _PausedTag(),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: visible.isEmpty
                    ? _EmptyState(
                        title: !_recorder.isInstalled && calls.isEmpty
                            ? 'Capture is not available on this platform'
                            : calls.isEmpty
                            ? 'No calls yet'
                            : 'No calls match',
                        subtitle: calls.isEmpty && _recorder.isInstalled
                            ? 'Requests made by the app show up here.'
                            : null,
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: DevtoolSpacing.padding),
                        itemBuilder: (context, index) {
                          final call = visible[index];
                          return _CallRow(call: call, onTap: () => _open(call));
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _countLabel(int count) => count == 1 ? '1 call' : '$count calls';

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: DevtoolColors.border),
    );

    return TextField(
      key: DevtoolKeys.networkSearchField,
      controller: controller,
      autocorrect: false,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: theme.textTheme.bodyMedium,
      cursorColor: DevtoolColors.primary,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: DevtoolColors.surface,
        hintText: 'Filter by URL, method or status',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: DevtoolColors.textSecondary),
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear filter',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: controller.clear,
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: DevtoolColors.primary)),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.counts, required this.onSelected});

  final _StatusFilter selected;
  final Map<_StatusFilter, int> counts;
  final ValueChanged<_StatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = [
      for (final filter in _StatusFilter.values)
        if (filter == _StatusFilter.all || filter == selected || counts[filter]! > 0) filter,
    ];

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DevtoolSpacing.padding),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return _FilterPill(
            key: DevtoolKeys.networkStatusFilter(filter.id),
            label: filter.label,
            count: counts[filter]!,
            color: filter.group == null ? null : statusColor(filter.group!),
            selected: filter == selected,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final textStyle = Theme.of(context).textTheme.labelSmall!;

    return Material(
      color: selected ? DevtoolColors.primary.withValues(alpha: 0.16) : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: selected ? DevtoolColors.primary.withValues(alpha: 0.6) : DevtoolColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: textStyle.copyWith(
                  fontSize: 12,
                  color: selected ? DevtoolColors.textPrimary : DevtoolColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: textStyle.copyWith(
                  fontSize: 12,
                  color: DevtoolColors.textSecondary.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedTag extends StatelessWidget {
  const _PausedTag();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: DevtoolColors.warning, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('Paused', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DevtoolColors.warning)),
      ],
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.call, required this.onTap});

  final NetworkCall call;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = call.duration;
    final slow = duration != null && duration.inMilliseconds >= 1000;

    return InkWell(
      key: DevtoolKeys.networkCallRow(call.id),
      onTap: onTap,
      hoverColor: DevtoolColors.hover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DevtoolSpacing.padding, vertical: 13),
        child: Row(
          children: [
            NetworkStatusPill(call: call),
            const SizedBox(width: 12),
            SizedBox(
              width: 58,
              child: Text(
                call.method,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                displayUrl(call.uri),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              duration == null ? '-' : formatDuration(duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: slow ? DevtoolColors.warning : DevtoolColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
