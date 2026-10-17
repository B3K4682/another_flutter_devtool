import 'network_usage_tracker.dart';

/// Web has no dart:io HttpClient, so nothing is tracked there.
bool installNetworkUsageOverrides(NetworkUsageTracker tracker) => false;
