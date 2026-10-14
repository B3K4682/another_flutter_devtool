import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'my_custom_tool.dart';

void main() {
  // For tracking startup time.
  AnotherFlutterDevtool.markStartup();
  // Your custom tools.
  // Could be in a separate file.
  DevtoolTools.registerAll([const MyCustomTool(), const MyCustomTool2()]);

  runApp(
    AnotherFlutterDevtool(
      config: const DevtoolConfig(
        // Can be kDebugMode or your own condition.
        enabled: kDebugMode,
        sections: [GeneralSection(), playgroundSection],
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const CounterPage(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devtool Example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Drag the code icon around, tap it to open the devtool.',
            ),
            const SizedBox(height: 16),
            Text(
              'Count: $_count',
              key: const Key('counter_text'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
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
