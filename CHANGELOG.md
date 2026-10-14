# Changelog

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
