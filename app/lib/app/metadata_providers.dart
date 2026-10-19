import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/domain/app_info.dart';
import '../core/domain/export_metadata.dart';
import 'metadata_service.dart';

part 'metadata_providers.g.dart';

/// Shared by exports and the About screen.
@Riverpod(keepAlive: true)
Future<AppInfo> appInfo(Ref ref) => AppInfoService().load();

@Riverpod(keepAlive: true)
ExportMetadataService exportMetadataService(Ref ref) => ExportMetadataService(
  loadAppInfo: () => ref.read(appInfoProvider.future),
  loadDeviceInfo: DeviceInfoService().load,
);
