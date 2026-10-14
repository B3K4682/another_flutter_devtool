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
  config: const DevtoolConfig(enabled: kDebugMode),
  child: const ExampleApp(),
)
```

## Integration tests

`[integration_test/launcher_test.dart](integration_test/launcher_test.dart)` covers the same behaviour on a real device or emulator:

```sh
flutter test integration_test
```

Widget tests for the package itself live in `[../test](../test)`.