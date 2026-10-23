import 'package:flutter/material.dart';

import '../theme/devtool_theme.dart';
import 'network_call.dart';
import 'network_format.dart';

/// Status code tinted by its class; a spinner while pending, `ERR` when failed.
class NetworkStatusPill extends StatelessWidget {
  const NetworkStatusPill({super.key, required this.call});

  final NetworkCall call;

  @override
  Widget build(BuildContext context) {
    final group = call.statusGroup;
    final color = statusColor(group);
    final code = call.statusCode;

    return Container(
      width: 44,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: group == NetworkStatusGroup.pending
          ? const SizedBox.square(
              dimension: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: DevtoolColors.textSecondary),
            )
          : Text(
              code?.toString() ?? 'ERR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
    );
  }
}
