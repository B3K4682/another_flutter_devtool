import 'package:flutter/foundation.dart';

/// Traffic counted for a single host since launch.
@immutable
class HostUsage {
  const HostUsage({required this.host, this.bytesReceived = 0, this.bytesSent = 0, this.requests = 0});

  final String host;
  final int bytesReceived;
  final int bytesSent;
  final int requests;

  int get total => bytesReceived + bytesSent;
}

/// Snapshot of all HTTP traffic counted since launch.
@immutable
class NetworkUsageStats {
  const NetworkUsageStats({this.bytesReceived = 0, this.bytesSent = 0, this.requestCount = 0, this.hosts = const {}});

  static const empty = NetworkUsageStats();

  final int bytesReceived;
  final int bytesSent;
  final int requestCount;

  /// Per-host usage, keyed by host name.
  final Map<String, HostUsage> hosts;

  int get total => bytesReceived + bytesSent;

  /// The [count] hosts that received the most data, largest first.
  List<HostUsage> topHosts([int count = 5]) {
    final sorted = hosts.values.toList()
      ..sort((a, b) {
        final byReceived = b.bytesReceived.compareTo(a.bytesReceived);
        return byReceived != 0 ? byReceived : b.requests.compareTo(a.requests);
      });
    return sorted.take(count).toList(growable: false);
  }
}
