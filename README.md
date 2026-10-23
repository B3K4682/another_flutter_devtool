# another_flutter_devtool

An in-app devtool for Flutter. Wrap your app, and a small draggable launcher button appears on top of it. Tap it to open a full-screen devtool panel without leaving the app.

> **Early stage:** 0.5.0 ships the launcher, the panel, the App Information, Internet Data Usage and Configuration tools, and the Network section. More built-in tools are coming in future releases.

## Features

- Floating launcher button that can be dragged anywhere inside the safe area, with an optional app version badge.
- Full-screen panel that closes with the close button or the system back button.
- App Information tool: app version and build number, device model, OS version, current flavor and startup time.
- Internet Data Usage tool: data received, sent and total, request count and top hosts since launch. Works with Dio and `http` with no setup.
- Network section: every HTTP call with its request, response and error. Search, filter by status, pause recording, export everything or a single call as JSON, and copy a call as cURL. Works with Dio and `http` with no setup.
- Configuration tool: type a route like `/example` to close the devtool and jump straight to that screen. Works with any router.
- Extensible: write your own section and tool, and it shows up alongside the built-in ones.
- Fully isolated from your app: the panel has its own `MaterialApp` and theme, and your app keeps working underneath.
- Turned off by default, so it is easy to keep out of release builds.
- Stable widget keys for testing.



## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  another_flutter_devtool: ^0.5.0
```



## Usage

Wrap the widget you pass to `runApp`:

```dart
import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  // For tracking startup time. (optional)
  AnotherFlutterDevtool.markStartup();

  runApp(
    AnotherFlutterDevtool(
      config: const DevtoolConfig(enabled: kDebugMode),
      child: const MyApp(),
    ),
  );
}
```

That already gives you the General section with the App Information, Internet Data Usage and Configuration cards in it.

### Navigation

The Configuration card has a route input. Since the devtool panel runs in its own
`MaterialApp`, tell it how to reach your app's router with `onNavigate`; the devtool
closes and then calls it with the typed route:

```dart
final navigatorKey = GlobalKey<NavigatorState>();

AnotherFlutterDevtool(
  config: DevtoolConfig(
    enabled: kDebugMode,
    sections: [
      GeneralSection(
        configuration: ConfigurationTool(
          onNavigate: (route) => navigatorKey.currentState?.pushNamed(route),
        ),
      ),
    ],
  ),
  child: MaterialApp(navigatorKey: navigatorKey, routes: {...}),
);
```

With go_router, use `onNavigate: (route) => router.go(route)` instead. Without
`onNavigate`, the input stays disabled.

### Network

Add `NetworkSection` to see every HTTP call made through dart:io's `HttpClient`
(Dio, `http`, `Image.network`). It is not available on web.

```dart
const DevtoolConfig(
  enabled: kDebugMode,
  sections: [GeneralSection(), NetworkSection()],
);
```

- The list shows status, method, URL and duration, newest first. Filter it by URL, method or status
  (`post 404` matches both), or narrow it down with the 2xx / 3xx / 4xx / 5xx / Failed chips.
- Tap a call for its query parameters, headers, bodies (JSON is pretty-printed) and error with stack trace.
- Export shares every recorded call (or a single call from its page) as a `.json` file. `Authorization`,
  `Proxy-Authorization`, `Cookie` and `Set-Cookie` values are masked in exports; change that with
  `NetworkSection(redactedHeaders: {...})`. Copy as cURL is not masked.
- The last 500 calls are kept, bodies are capped at 256 KB, and binary bodies such as images are not stored.
  Pass `NetworkSection(recorder: NetworkRecorder(maxCalls: 1000))` to change the limits.

### Configuration

```dart
const DevtoolConfig(
  enabled: true, // false renders only your app
  launcher: LauncherConfig(
    enabled: true, // false never shows the launcher
    initiallyVisible: true, // whether the launcher is visible on start
  ),
  sections: [GeneralSection()], // cards on the devtool home screen
);
```



### Sections and tools

`sections` holds the cards shown on the home screen; it never holds tools. A tool
declares the section it belongs to and shows up there on its own. `GeneralSection`
ships with `AppInfoTool`, `NetworkUsageTool` and `ConfigurationTool`, so you get app
version, device, OS, flavor, startup time and network usage without any wiring.

To add your own, create a section, point a tool at it, and register the tool once:

```dart
const playgroundSection = DevtoolSection(
  id: 'playground',
  title: 'Playground',
  icon: Icons.science_rounded,
);

class MyCustomTool extends DevtoolTool {
  const MyCustomTool();

  @override
  String get id => 'my_custom_tool';

  @override
  String get title => 'My Custom Tool';

  @override
  IconData get icon => Icons.extension_rounded;

  @override
  String get description => 'Shown in the card\'s info modal.';

  @override
  DevtoolSection get section => playgroundSection; // belongs to

  @override
  Widget build(BuildContext context, DevtoolController controller) => DevtoolCard(
        icon: icon,
        title: title,
        description: description,
        child: const DevtoolInfoRow(label: 'Status', value: 'It works'),
      );
}

void main() {
  DevtoolTools.register(const MyCustomTool());

  runApp(
    AnotherFlutterDevtool(
      config: const DevtoolConfig(
        enabled: kDebugMode,
        sections: [GeneralSection(), playgroundSection],
      ),
      child: const MyApp(),
    ),
  );
}
```

Registering a tool whose id matches a built-in replaces it, so
`DevtoolTools.register(const AppInfoTool(flavor: 'Staging'))` customises the
built-in card. `GeneralSection(appInfo: null)` hides it instead, and the same works
for `networkUsage` and `configuration`.

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