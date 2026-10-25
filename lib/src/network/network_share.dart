import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'network_call.dart';

/// Shares [json] as a .json file, or copies it when file sharing is unavailable.
Future<void> shareJson(BuildContext context, {required String json, required String fileName}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(json), mimeType: 'application/json', name: fileName)],
        fileNameOverrides: [fileName],
        sharePositionOrigin: origin,
      ),
    );
    if (result.status != ShareResultStatus.unavailable) return;
  } catch (_) {
    // Falls through to the clipboard.
  }
  await Clipboard.setData(ClipboardData(text: json));
  messenger?.showSnackBar(const SnackBar(content: Text('Sharing is unavailable, JSON copied to clipboard')));
}

/// `network_calls_2026-10-22_20-11.json`.
String callsFileName(DateTime now) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'network_calls_${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}-${two(now.minute)}.json';
}

/// `GET_posts_20-11-05.json`.
String callFileName(NetworkCall call) {
  String two(int value) => value.toString().padLeft(2, '0');
  final segments = call.uri.pathSegments.where((segment) => segment.isNotEmpty);
  final name = (segments.isEmpty ? call.uri.host : segments.last).replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final time = call.startedAt;
  return '${call.method}_${name}_${two(time.hour)}-${two(time.minute)}-${two(time.second)}.json';
}
