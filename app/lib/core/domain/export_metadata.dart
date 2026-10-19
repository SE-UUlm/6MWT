import 'app_info.dart';

class ExportMetadataService {
  ExportMetadataService({
    required this.loadAppInfo,
    required this.loadDeviceInfo,
  });

  final Future<AppInfo> Function() loadAppInfo;
  final Future<Map<String, dynamic>> Function() loadDeviceInfo;

  Future<Map<String, dynamic>> getMetadata() async => {
    'deviceInfo': await loadDeviceInfo(),
    'appInfo': (await loadAppInfo()).toJson(),
  };
}
