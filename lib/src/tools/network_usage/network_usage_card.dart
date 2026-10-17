import 'package:flutter/material.dart';

import '../../keys.dart';
import '../../theme/devtool_theme.dart';
import '../../widgets/devtool_card.dart';
import '../../widgets/devtool_info_row.dart';
import 'byte_format.dart';
import 'network_usage_tool.dart';

/// Card rendering the traffic counted by [NetworkUsageTool].
class NetworkUsageCard extends StatelessWidget {
  const NetworkUsageCard({super.key, required this.tool});

  final NetworkUsageTool tool;

  @override
  Widget build(BuildContext context) {
    final tracker = tool.tracker;
    final theme = Theme.of(context);

    return DevtoolCard(
      key: DevtoolKeys.toolCard(tool.id),
      icon: tool.icon,
      title: tool.title,
      description: tool.description,
      infoButtonKey: DevtoolKeys.toolInfoButton(tool.id),
      child: ListenableBuilder(
        listenable: tracker,
        builder: (context, _) {
          final stats = tracker.stats;
          final topHosts = stats.topHosts(tool.topHostCount);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!tracker.isInstalled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Tracking is not available on this platform.', style: theme.textTheme.bodySmall),
                ),
              DevtoolInfoRow(label: 'Received', value: formatBytes(stats.bytesReceived)),
              DevtoolInfoRow(label: 'Sent', value: formatBytes(stats.bytesSent)),
              DevtoolInfoRow(label: 'Total', value: formatBytes(stats.total)),
              DevtoolInfoRow(label: 'Requests', value: '${stats.requestCount}'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('TOP HOSTS (RECEIVED)', style: theme.textTheme.labelSmall),
              ),
              if (topHosts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('No requests yet', style: theme.textTheme.bodySmall),
                )
              else
                for (final host in topHosts)
                  DevtoolInfoRow(label: host.host, value: formatBytes(host.bytesReceived)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: DevtoolKeys.networkUsageResetButton,
                  style: TextButton.styleFrom(
                    foregroundColor: DevtoolColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: tracker.reset,
                  child: const Text('Reset'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
