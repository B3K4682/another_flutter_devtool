# another_flutter_devtool_example

A small counter app used to try out and manually test `[another_flutter_devtool](../)`. It depends on the package through a local path, so any change you make in `lib/` shows up here right away.

## Run it

```sh
cd example
flutter pub get
flutter run
```

The devtool is wired up in `[lib/main.dart](lib/main.dart)` and only enabled in debug mode:

```dart
AnotherFlutterDevtool(
  config: DevtoolConfig(
    enabled: kDebugMode,
    sections: [
      GeneralSection(
        configuration: ConfigurationTool(onNavigate: (route) => navigatorKey.currentState?.pushNamed(route)),
      ),
      playgroundSection,
    ],
  ),
  child: const ExampleApp(),
)
```

Things to try:

- **Fetch with http** and **Fetch with Dio** buttons generate traffic for the Internet Data Usage card.
- In the Configuration card, type `/example` or `/test` and press Go to close the devtool and open that page.
- The Playground section hosts the custom tools from `[lib/my_custom_tool.dart](lib/my_custom_tool.dart)`.

## Integration tests

`[integration_test/launcher_test.dart](integration_test/launcher_test.dart)` covers the same behaviour on a real device or emulator:

```sh
flutter test integration_test
```

Widget tests for the package itself live in `[../test](../test)`.