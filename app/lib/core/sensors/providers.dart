import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'location_service.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) => LocationService();
