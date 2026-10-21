import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/domain/app_info.dart';
import 'platform_metadata.dart';

class AppInfoService {
  AppInfoService({
    Future<PackageInfo> Function()? loadPackageInfo,
    Future<String?> Function()? loadCommitHash,
  }) : _loadPackageInfo = loadPackageInfo ?? PackageInfo.fromPlatform,
       _loadCommitHash = loadCommitHash ?? PlatformMetadata.getCommitHash;

  final Future<PackageInfo> Function() _loadPackageInfo;
  final Future<String?> Function() _loadCommitHash;

  Future<AppInfo> load() async {
    final package = await readMetadata('app version', _loadPackageInfo);
    final commit = await readMetadata('commit hash', _loadCommitHash);

    return AppInfo(
      version: package?.version,
      buildNumber: package?.buildNumber,
      commitHash: commit,
    );
  }
}

class DeviceInfoService {
  DeviceInfoService({
    String? operatingSystem,
    String? operatingSystemVersion,
    Future<AndroidDeviceInfo> Function()? loadAndroidInfo,
    Future<IosDeviceInfo> Function()? loadIosInfo,
    Future<String?> Function()? loadAndroidId,
  }) : _os = operatingSystem ?? Platform.operatingSystem,

       _osVersion = operatingSystemVersion ?? Platform.operatingSystemVersion,

       _loadAndroidInfo =
           loadAndroidInfo ?? (() => DeviceInfoPlugin().androidInfo),

       _loadIosInfo = loadIosInfo ?? (() => DeviceInfoPlugin().iosInfo),

       _loadAndroidId = loadAndroidId ?? PlatformMetadata.getAndroidId;

  final String _os;
  final String _osVersion;
  final Future<AndroidDeviceInfo> Function() _loadAndroidInfo;
  final Future<IosDeviceInfo> Function() _loadIosInfo;
  final Future<String?> Function() _loadAndroidId;

  Future<Map<String, dynamic>> load() async {
    final result = <String, dynamic>{
      'manufacturer': null,
      'model': null,
      'os': _os,
      'osVersion': null,
      'deviceId': null,
      'deviceIdType': null,
    };

    if (_os == 'android') {
      final info = await readMetadata('Android device', _loadAndroidInfo);
      result.addAll({
        'manufacturer': info?.manufacturer,
        'model': info?.model,
        'osVersion': info?.version.release,
        'deviceId': await readMetadata('Android ID', _loadAndroidId),
        'deviceIdType': 'androidId',
      });
    } else if (_os == 'ios') {
      final info = await readMetadata('iOS device', _loadIosInfo);
      result.addAll({
        'manufacturer': 'Apple',
        'model': info?.utsname.machine,
        'osVersion': info?.systemVersion,
        'deviceId': info?.identifierForVendor,
        'deviceIdType': 'identifierForVendor',
      });
    } else {
      result['osVersion'] = _osVersion;
    }

    return result;
  }
}
