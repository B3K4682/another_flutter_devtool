# Changelog

## 0.5.1

Code style update. No behavior changes.

### Changed

* Formatted all Dart code with `dart format` at a page width of 120, set in `analysis_options.yaml`.

## 0.5.0

Adds the Network section.

### Added

* `NetworkSection`, recording every HTTP call made through dart:io's `HttpClient` (Dio, `http`, images):
  * A list of calls with status (coloured by class), method, URL and duration, newest first.
  * Search by URL, method or status, status filter chips (2xx, 3xx, 4xx, 5xx, Failed) and a call count.
  * Pause and resume recording, clear with undo, and export every call as a `.json` file.
  * A details page per call: query parameters, request and response headers and bodies, the error with its stack trace, Copy as cURL and a single-call JSON export.
  * Sensitive headers are masked in exports (`redactedHeaders`).
  * Keeps the last 500 calls, caps bodies at 256 KB and skips binary bodies (`NetworkRecorder(maxCalls:, maxBodyBytes:)`).
* `NetworkRecorder`, `NetworkCall`, `exportCallsJson`, `exportCallJson` and `toCurl`.
* `HttpCallObserver` and `DevtoolHttp`, so any tool can observe HTTP calls through the shared hook.
* `DevtoolSection.init`, `dispose` and `buildPage`, so a section can show its own page instead of tool cards.
* `DevtoolKeys` for the Network section.
* Dependency on `share_plus`.

### Changed

* `NetworkUsageTracker` now uses the shared HTTP hook. `NetworkUsageHttpOverrides` is replaced by `DevtoolHttpOverrides`.

## 0.4.0

Adds the Configuration tool with route navigation.

### Added

* `ConfigurationTool` in the General section, with a Navigation input: type a route like `/example` and press Go (or submit from the keyboard) to close the devtool and open that route.
  * Takes an `onNavigate` callback, so it works with `Navigator`, go_router, auto_route or any other router.
  * Trims the input, ignores empty input and adds a leading `/` when it is missing.
  * Without `onNavigate`, the input is disabled and the card explains how to enable it.
* `DevtoolController.isPanelOpen`, `openPanel()` and `closePanel()`, so tools can open or close the devtool panel.
* `DevtoolKeys.configurationRouteField` and `DevtoolKeys.configurationGoButton`.
* Example app routes `/example` and `/test` to demo the tool.

### Changed

* `GeneralSection` now ships with `AppInfoTool`, `NetworkUsageTool` and `ConfigurationTool`. Pass `configuration: null` to hide the new card.
* Whether the panel is open now lives in `DevtoolController` instead of the `AnotherFlutterDevtool` widget.

## 0.3.0

Adds the Internet Data Usage tool.

### Added

* `NetworkUsageTool` in the General section, counting HTTP traffic since launch:
  * Data received, data sent and the total, formatted as B, KB, MB or GB.
  * Number of requests made.
  * Top hosts by data received (5 by default, configurable via `topHostCount`).
  * Reset button to start counting from zero.
* Works with Dio, the `http` package and anything else built on `dart:io`'s `HttpClient`, with no setup in the app. Traffic is captured through a global `HttpOverrides` that chains any overrides the app already installed.
* `NetworkUsageTracker` (`NetworkUsageTracker.instance` by default) with `stats`, `reset()` and `record*` methods; pass your own via `NetworkUsageTool(tracker: ...)`.
* `NetworkUsageStats` and `HostUsage` snapshots, plus the `formatBytes` helper.
* `DevtoolKeys.networkUsageResetButton`.
* Example app buttons that fetch with `http` and Dio to demo the tool.

### Changed

* `GeneralSection` now ships with `AppInfoTool` and `NetworkUsageTool`. Pass `networkUsage: null` to hide the new card.

### Known limitations

* Not available on web, where the card says tracking is unavailable.
* Native clients that bypass `HttpClient` (`cupertino_http`, `native_dio_adapter`) are not counted.
* Header sizes are estimated, and gzip responses are counted after decompression.

## 0.2.0

Adds the tool system and the first built-in tool.

### Added

* Sections and tools:
  * `DevtoolSection` for the cards on the devtool home screen, laid out two per row.
  * `DevtoolTool` as the base class for tool cards; each tool declares the `section` it belongs to.
  * `DevtoolConfig.sections` to pick which sections are shown, defaulting to `[GeneralSection()]`.
  * `DevtoolTools` registry to add app-defined tools: `register`, `registerAll`, `unregister`, `clear`. A registered tool whose id matches a built-in replaces it.
  * `GeneralSection`, which ships with `AppInfoTool` and accepts `appInfo: null` to hide it.
* `AppInfoTool` in the General section, showing app version and build number, device model, OS version, current flavor and app startup time.
  * `AppInfoSource` with the default `PlatformAppInfoSource` (`package_info_plus`, `device_info_plus`) and `StaticAppInfoSource` for tests or custom values.
  * `AppFlavor` detection (Debug, Profile, Release) with semantic colors, overridable via `AppInfoTool(flavor: ...)`.
  * `AnotherFlutterDevtool.markStartup()` and `DevtoolStartupTracker`, which measure the time to the first rasterized frame.
  * Toggle to show the app version below the launcher button, persisted with `shared_preferences`.
* Version badge under the launcher button, driven by that toggle.
* Design system: `DevtoolColors`, `DevtoolSpacing` and `DevtoolTheme.dark()`, with the Inter font bundled.
* Reusable widgets for tool authors: `DevtoolCard` (leading icon, title and an info button), `showDevtoolInfoModal`, `DevtoolInfoRow` and `DevtoolSwitchRow`.
* `DevtoolController` for shared state and persisted settings, exposed to tools and the launcher through `DevtoolScope`.
* `DevtoolStorage` with `SharedPreferencesDevtoolStorage` and `InMemoryDevtoolStorage`, overridable via `DevtoolConfig.storage`.
* More `DevtoolKeys`: `versionBadge`, `infoModal`, `infoModalCloseButton`, `sectionCard`, `sectionPage`, `toolCard` and `toolInfoButton`.

### Changed

* The devtool panel now opens on a section grid instead of an empty screen. Section pages are pushed routes, so the system back button returns to the grid and only closes the panel from the home screen.
* The panel uses `DevtoolTheme.dark()` instead of `ThemeData.dark()`.

## 0.1.0

Initial release.

### Added

* `AnotherFlutterDevtool` widget that wraps your app and overlays the devtool on top of it.
* `DevtoolConfig` to turn the devtool on or off (`enabled`, defaults to `false`). When disabled, only the wrapped child is rendered.
* `LauncherConfig` to control the floating launcher (`enabled`, `initiallyVisible`).
* Floating, draggable launcher button (36x36, rounded, code icon):
  * Starts near the top-left corner of the safe area.
  * Can be dragged anywhere and is clamped to the safe area.
  * Keeps its position after the panel is closed.
* Full-screen devtool panel opened by tapping the launcher:
  * Closes with the close button or the system back gesture/button.
  * Has its own dark-themed `MaterialApp`, so it does not depend on the host app's theme or navigator.
  * Panel content is empty in this release; tools will be added in later versions.
* The host app stays fully interactive while the launcher is shown.
* `DevtoolKeys` with stable keys (`launcher`, `panel`, `closeButton`) for widget and integration tests.
* Example app with integration tests.
