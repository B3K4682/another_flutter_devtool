import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../keys.dart';
import '../theme/devtool_theme.dart';
import '../tools/network_usage/byte_format.dart';
import 'network_call.dart';
import 'network_format.dart';
import 'network_recorder.dart';
import 'network_redaction.dart';
import 'network_status_pill.dart';

/// Floating card over the app showing the newest recorded call; drag to move, tap to expand.
class LastCallOverlay extends StatefulWidget {
  const LastCallOverlay({
    super.key,
    required this.recorder,
    required this.offset,
    required this.onMoved,
    required this.onOpenDetails,
    this.redactedQueryParameters = defaultRedactedQueryParameters,
  });

  static const double maxWidth = 360;
  static const double rowHeight = 44;
  static const double margin = 16;

  final NetworkRecorder recorder;

  /// Top-left position of the collapsed row; null places it near the bottom center.
  final Offset? offset;
  final ValueChanged<Offset> onMoved;
  final ValueChanged<NetworkCall> onOpenDetails;
  final Set<String> redactedQueryParameters;

  @override
  State<LastCallOverlay> createState() => _LastCallOverlayState();
}

class _LastCallOverlayState extends State<LastCallOverlay> {
  static const double _radius = 10;

  bool _expanded = false;
  Offset _dragStartPointer = Offset.zero;
  Offset _dragStartPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final width = math.max(
      0.0,
      math.min(screen.width - padding.horizontal - LastCallOverlay.margin * 2, LastCallOverlay.maxWidth),
    );
    final bounds = Rect.fromLTRB(
      padding.left,
      padding.top,
      math.max(padding.left, screen.width - padding.right - width),
      math.max(padding.top, screen.height - padding.bottom - LastCallOverlay.rowHeight),
    );
    final position = _clamp(
      widget.offset ?? Offset((screen.width - width) / 2, bounds.bottom - LastCallOverlay.margin),
      bounds,
    );
    final opensUpward = position.dy + LastCallOverlay.rowHeight / 2 > screen.height / 2;

    return Positioned(
      left: position.dx,
      top: opensUpward ? null : position.dy,
      bottom: opensUpward ? screen.height - position.dy - LastCallOverlay.rowHeight : null,
      width: width,
      child: Theme(
        data: DevtoolTheme.dark(),
        child: GestureDetector(
          key: DevtoolKeys.lastCallOverlay,
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (details) {
            _dragStartPointer = details.globalPosition;
            _dragStartPosition = position;
          },
          onPanUpdate: (details) =>
              widget.onMoved(_clamp(_dragStartPosition + details.globalPosition - _dragStartPointer, bounds)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DevtoolColors.surface,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: DevtoolColors.border),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius - 1),
              child: Material(
                type: MaterialType.transparency,
                child: ListenableBuilder(
                  listenable: widget.recorder,
                  builder: (context, _) => _buildCard(widget.recorder.latest, opensUpward),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(NetworkCall? call, bool opensUpward) {
    final url = call == null ? '' : redactUrl(call.uri, widget.redactedQueryParameters);
    final row = _SummaryRow(
      call: call,
      url: url,
      expanded: _expanded,
      onTap: () => setState(() => _expanded = !_expanded),
    );
    final details = AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: opensUpward ? Alignment.bottomCenter : Alignment.topCenter,
      child: _expanded && call != null
          ? _Details(call: call, url: url, onOpen: () => widget.onOpenDetails(call))
          : const SizedBox(width: double.infinity),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: opensUpward ? [details, row] : [row, details],
    );
  }

  Offset _clamp(Offset value, Rect bounds) =>
      Offset(value.dx.clamp(bounds.left, bounds.right), value.dy.clamp(bounds.top, bounds.bottom));
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.call, required this.url, required this.expanded, required this.onTap});

  final NetworkCall? call;
  final String url;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final call = this.call;
    final duration = call?.duration;

    return InkWell(
      onTap: call == null ? null : onTap,
      hoverColor: DevtoolColors.hover,
      child: SizedBox(
        height: LastCallOverlay.rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: call == null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No calls yet', style: theme.textTheme.bodySmall),
                )
              : Row(
                  children: [
                    NetworkStatusPill(call: call),
                    const SizedBox(width: 10),
                    Text(
                      call.method,
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayUrl(url),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      duration == null ? '-' : formatDuration(duration),
                      style: theme.textTheme.bodySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    Icon(
                      expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 18,
                      color: DevtoolColors.textSecondary,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.call, required this.url, required this.onOpen});

  final NetworkCall call;
  final String url;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final duration = call.duration;
    final error = call.error;
    final status = error != null
        ? error.toString()
        : call.statusCode == null
        ? 'Pending'
        : [call.statusCode, call.reasonPhrase].whereType<Object>().join(' ');

    return Container(
      key: DevtoolKeys.lastCallOverlayDetails,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: const BoxDecoration(
        color: DevtoolColors.background,
        border: Border.symmetric(horizontal: BorderSide(color: DevtoolColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(url, maxLines: 3, overflow: TextOverflow.ellipsis, style: monoStyle),
          const SizedBox(height: 8),
          _DetailRow(label: 'Status', value: status, color: statusColor(call.statusGroup)),
          _DetailRow(label: 'Started', value: formatTime(call.startedAt)),
          _DetailRow(label: 'Duration', value: duration == null ? '-' : formatDuration(duration)),
          _DetailRow(label: 'Sent', value: formatBytes(call.requestSize)),
          _DetailRow(label: 'Received', value: formatBytes(call.responseSize)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: DevtoolKeys.lastCallOpenDetailsButton,
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
