import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/walk_session_provider.dart';

/// Keeps the wall-clock deadline synchronized independently of the active route.
class WalkSessionLifecycle extends ConsumerStatefulWidget {
  const WalkSessionLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WalkSessionLifecycle> createState() =>
      _WalkSessionLifecycleState();
}

class _WalkSessionLifecycleState extends ConsumerState<WalkSessionLifecycle> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () {
        // Resuming the app alone must not initialize a session or its database.
        if (ref.exists(walkSessionProvider)) {
          ref.read(walkSessionProvider).synchronizeWithClock();
        }
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
