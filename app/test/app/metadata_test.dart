import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:six_minute_walk_test/app/metadata_service.dart';
import 'package:six_minute_walk_test/app/platform_metadata.dart';

class AndroidInfo extends Fake implements AndroidDeviceInfo {
  @override
  String get manufacturer => 'Google';
  @override
  String get model => 'Pixel 9';
  @override
  AndroidBuildVersion get version => AndroidVersion();
}

class AndroidVersion extends Fake implements AndroidBuildVersion {
  @override
  String get release => '16';
}

class IosInfo extends Fake implements IosDeviceInfo {
  @override
  String get systemVersion => '18.0';
  @override
  String? get identifierForVendor => 'vendor-id';
  @override
  IosUtsname get utsname => IosUtsname.setMockInitialValues(
    sysname: '',
    nodename: '',
    release: '',
    version: '',
    machine: 'iPhone17,1',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final package = PackageInfo(
    appName: '6MWT',
    packageName: 'test',
    version: '2.1.0',
    buildNumber: '42',
  );

  test(
    'installed version and native commit are available independently',
    () async {
      final service = AppInfoService(
        loadPackageInfo: () async => package,
        loadCommitHash: () async => 'abc123',
      );
      expect((await service.load()).toJson(), {
        'version': '2.1.0',
        'buildNumber': '42',
        'commitHash': 'abc123',
      });
      final failedVersion = AppInfoService(
        loadPackageInfo: () async =>
            throw PlatformException(code: 'unavailable'),
        loadCommitHash: () async => 'abc123',
      );
      expect((await failedVersion.load()).toJson(), {
        'version': null,
        'buildNumber': null,
        'commitHash': 'abc123',
      });
    },
  );

  test('missing or failed commit leaves installed version intact', () async {
    for (final loader in <Future<String?> Function()>[
      () async => null,
      () async => throw MissingPluginException(),
    ]) {
      expect(
        (await AppInfoService(
          loadPackageInfo: () async => package,
          loadCommitHash: loader,
        ).load()).toJson(),
        {'version': '2.1.0', 'buildNumber': '42', 'commitHash': null},
      );
    }
  });

  test('Android exports OS ID separately from model information', () async {
    final service = DeviceInfoService(
      operatingSystem: 'android',
      loadAndroidInfo: () async => AndroidInfo(),
      loadAndroidId: () async => 'os-id',
    );
    expect(await service.load(), {
      'manufacturer': 'Google',
      'model': 'Pixel 9',
      'os': 'android',
      'osVersion': '16',
      'deviceId': 'os-id',
      'deviceIdType': 'androidId',
    });
  });

  test('Android ID and device lookup failures are independent', () async {
    final noInfo = await DeviceInfoService(
      operatingSystem: 'android',
      loadAndroidInfo: () async => throw MissingPluginException(),
      loadAndroidId: () async => 'os-id',
    ).load();
    expect(noInfo['deviceId'], 'os-id');
    expect(noInfo['model'], isNull);
    final noId = await DeviceInfoService(
      operatingSystem: 'android',
      loadAndroidInfo: () async => AndroidInfo(),
      loadAndroidId: () async => throw PlatformException(code: 'denied'),
    ).load();
    expect(noId['model'], 'Pixel 9');
    expect(noId['deviceId'], isNull);
  });

  test('iOS uses machine model and vendor ID', () async {
    expect(
      await DeviceInfoService(
        operatingSystem: 'ios',
        loadIosInfo: () async => IosInfo(),
      ).load(),
      {
        'manufacturer': 'Apple',
        'model': 'iPhone17,1',
        'os': 'ios',
        'osVersion': '18.0',
        'deviceId': 'vendor-id',
        'deviceIdType': 'identifierForVendor',
      },
    );
    final failed = await DeviceInfoService(
      operatingSystem: 'ios',
      loadIosInfo: () async => throw MissingPluginException(),
    ).load();
    expect(failed['model'], isNull);
    expect(failed['deviceId'], isNull);
  });

  test('other platforms expose OS without an invented identifier', () async {
    expect(
      await DeviceInfoService(
        operatingSystem: 'linux',
        operatingSystemVersion: 'test-kernel',
      ).load(),
      {
        'manufacturer': null,
        'model': null,
        'os': 'linux',
        'osVersion': 'test-kernel',
        'deviceId': null,
        'deviceIdType': null,
      },
    );
  });

  test('platform channel calls native commit and Android ID methods', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(PlatformMetadata.channel, (call) async {
      return switch (call.method) {
        'getCommitHash' => 'built-commit',
        'getAndroidId' => 'native-id',
        _ => throw MissingPluginException(),
      };
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(PlatformMetadata.channel, null),
    );
    expect(await PlatformMetadata.getCommitHash(), 'built-commit');
    expect(await PlatformMetadata.getAndroidId(), 'native-id');
  });
}
