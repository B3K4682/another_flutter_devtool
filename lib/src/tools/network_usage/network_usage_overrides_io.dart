import 'dart:io';

import 'network_usage_tracker.dart';
import 'tracking_http_client.dart';

/// Wraps every new HttpClient so its traffic is counted by [tracker].
bool installNetworkUsageOverrides(NetworkUsageTracker tracker) {
  final current = HttpOverrides.current;
  if (current is NetworkUsageHttpOverrides) return true;
  HttpOverrides.global = NetworkUsageHttpOverrides(tracker, previous: current);
  return true;
}

/// Chains [previous] so overrides installed by the app keep working.
class NetworkUsageHttpOverrides extends HttpOverrides {
  NetworkUsageHttpOverrides(this.tracker, {this.previous});

  final NetworkUsageTracker tracker;
  final HttpOverrides? previous;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final inner = previous?.createHttpClient(context) ?? super.createHttpClient(context);
    return TrackingHttpClient(inner, tracker);
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) =>
      previous?.findProxyFromEnvironment(url, environment) ?? super.findProxyFromEnvironment(url, environment);
}
