import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/devtool_test_harness.dart';

void main() {
  group('AppInfoData', () {
    test('combines version and build number', () {
      expect(testAppInfo.versionLabel, '1.2.3 (42)');
      expect(testAppInfo.badgeLabel, 'v1.2.3 (42)');
    });

    test('omits an empty build number', () {
      const data = AppInfoData(
        appName: 'Example',
        version: '1.2.3',
        buildNumber: '',
        deviceModel: 'Pixel 8',
        osVersion: 'Android 15',
        flavor: 'Debug',
      );

      expect(data.versionLabel, '1.2.3');
    });

    test('formats the startup duration', () {
      expect(testAppInfo.startupLabel, '412 ms');
      expect(
        testAppInfo.copyWith(startupDuration: const Duration(milliseconds: 1500)).startupLabel,
        '1.50 s',
      );
    });

    test('reports a pending startup measurement', () {
      const data = AppInfoData(
        appName: 'Example',
        version: '1.2.3',
        buildNumber: '42',
        deviceModel: 'Pixel 8',
        osVersion: 'Android 15',
        flavor: 'Debug',
      );

      expect(data.startupLabel, 'Measuring...');
    });
  });

  group('AppFlavor', () {
    test('resolves to Debug under flutter test', () {
      expect(AppFlavor.current, AppFlavor.debug);
      expect(AppFlavor.current.label, 'Debug');
    });
  });

  group('AppInfoState', () {
    test('loads data from its source and notifies', () async {
      final state = AppInfoState(source: const StaticAppInfoSource(testAppInfo));
      var notifications = 0;
      state.addListener(() => notifications++);

      expect(state.data, isNull);
      await state.load();

      expect(state.data?.deviceModel, 'Pixel 8');
      expect(notifications, 1);
    });

    test('a custom flavor overrides the detected one', () async {
      final state = AppInfoState(source: const StaticAppInfoSource(testAppInfo), flavor: 'Staging');
      await state.load();

      expect(state.data?.flavor, 'Staging');
    });
  });

  group('AppInfoTool', () {
    test('belongs to the General section', () {
      expect(const AppInfoTool().section, const GeneralSection());
    });
  });

  group('DevtoolController settings', () {
    test('seeds from storage and persists changes', () async {
      final storage = InMemoryDevtoolStorage({DevtoolController.showVersionBadgeKey: false});
      final controller = DevtoolController(
        config: DevtoolConfig(enabled: true, storage: storage),
        storage: storage,
      );

      controller.registerBoolSetting(DevtoolController.showVersionBadgeKey, defaultValue: true);
      expect(controller.showVersionBadge, isFalse);

      await controller.setShowVersionBadge(true);
      expect(controller.showVersionBadge, isTrue);
      expect(storage.getBool(DevtoolController.showVersionBadgeKey), isTrue);
    });

    test('falls back to the default when storage is empty', () {
      final controller = DevtoolController(
        config: const DevtoolConfig(enabled: true),
        storage: InMemoryDevtoolStorage(),
      );

      controller.registerBoolSetting(DevtoolController.showVersionBadgeKey, defaultValue: true);
      expect(controller.showVersionBadge, isTrue);
    });
  });
}
