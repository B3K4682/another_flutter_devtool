# another_flutter_devtool

An in-app devtool for Flutter. Wrap your app, and a small draggable launcher button appears on top of it. Tap it to open a full-screen devtool panel without leaving the app.

> **Early stage:** 0.1.0 ships the launcher and the panel shell. The panel is empty for now; actual tools are coming in future releases.

## Features

- Floating launcher button that can be dragged anywhere inside the safe area.
- Full-screen panel that closes with the close button or the system back button.
- Fully isolated from your app: the panel has its own `MaterialApp` and theme, and your app keeps working underneath.
- Turned off by default, so it is easy to keep out of release builds.
- Stable widget keys for testing.



## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  another_flutter_devtool: ^0.1.0
```



## Usage

Wrap the widget you pass to `runApp`:

```dart
import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    AnotherFlutterDevtool(
      config: const DevtoolConfig(enabled: kDebugMode),
      child: const MyApp(),
    ),
  );
}
```



### Configuration

```dart
const DevtoolConfig(
  enabled: true, // false renders only your app
  launcher: LauncherConfig(
    enabled: true, // false never shows the launcher
    initiallyVisible: true, // whether the launcher is visible on start
  ),
);
```



### Testing

Use `DevtoolKeys` to find devtool widgets in widget or integration tests:

```dart
await tester.tap(find.byKey(DevtoolKeys.launcher));
await tester.pumpAndSettle();
expect(find.byKey(DevtoolKeys.panel), findsOneWidget);

await tester.tap(find.byKey(DevtoolKeys.closeButton));
```



## Example

See the `[example](example)` folder for a runnable app and integration tests.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/B3K4682/another_flutter_devtool).