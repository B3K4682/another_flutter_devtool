import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'my_custom_tool.dart';

// Navigation key (works with all routers)
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // For tracking startup time.
  AnotherFlutterDevtool.markStartup();
  // Your custom tools.
  // Could be in a separate file.
  DevtoolTools.registerAll([const MyCustomTool(), const MyCustomTool2()]);

  runApp(
    AnotherFlutterDevtool(
      config: DevtoolConfig(
        // Can be kDebugMode or your own condition.
        enabled: kDebugMode,
        sections: [
          GeneralSection(
            // This configuration is required to navigate to a route.
            configuration: ConfigurationTool(onNavigate: (route) => navigatorKey.currentState?.pushNamed(route)),
          ),
          const NetworkSection(),
          playgroundSection,
        ],
      ),
      child: const ExampleApp(),
    ),
  );
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Devtool Example',
      navigatorKey: navigatorKey,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: const CounterPage(),
      routes: {
        '/example': (_) => const PlaceholderPage(title: '/example'),
        '/test': (_) => const PlaceholderPage(title: '/test'),
      },
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('You navigated to $title')),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0;
  String _lastResult = '';

  Future<void> _fetchWithHttp() =>
      _run(() async => (await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'))).statusCode);

  Future<void> _fetchWithDio() =>
      _run(() async => (await Dio().get<String>('https://httpbin.org/bytes/20480')).statusCode ?? 0);

  Future<void> _postJson() => _run(
    () async => (await http.post(
      Uri.parse('https://jsonplaceholder.typicode.com/posts?source=devtool'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer example-token'},
      body: '{"title": "Hello", "body": "From the devtool example", "userId": 1}',
    )).statusCode,
  );

  Future<void> _fetchStatus(int status) =>
      _run(() async => (await http.get(Uri.parse('https://httpbin.org/status/$status'))).statusCode);

  Future<void> _fetchUnreachable() =>
      _run(() async => (await http.get(Uri.parse('https://unreachable.invalid/ping'))).statusCode);

  Future<void> _run(Future<int> Function() request) async {
    try {
      final status = await request();
      if (mounted) setState(() => _lastResult = 'Status $status');
    } catch (error) {
      if (mounted) setState(() => _lastResult = 'Failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devtool Example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Drag the code icon around, tap it to open the devtool.'),
            const SizedBox(height: 16),
            Text('Count: $_count', key: const Key('counter_text'), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(onPressed: _fetchWithHttp, child: const Text('Fetch with http')),
                OutlinedButton(onPressed: _fetchWithDio, child: const Text('Fetch with Dio')),
                OutlinedButton(onPressed: _postJson, child: const Text('POST JSON')),
                OutlinedButton(onPressed: () => _fetchStatus(404), child: const Text('404')),
                OutlinedButton(onPressed: () => _fetchStatus(500), child: const Text('500')),
                OutlinedButton(onPressed: _fetchUnreachable, child: const Text('Unreachable host')),
              ],
            ),
            const SizedBox(height: 8),
            Text(_lastResult),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('increment_button'),
        onPressed: () => setState(() => _count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
