import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/metadata_service.dart';
import 'app_info.dart';

part 'export_metadata.g.dart';

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

@Riverpod(keepAlive: true)
ExportMetadataService exportMetadataService(Ref ref) => ExportMetadataService(
  loadAppInfo: () => ref.read(appInfoProvider.future),
  loadDeviceInfo: DeviceInfoService().load,
);
