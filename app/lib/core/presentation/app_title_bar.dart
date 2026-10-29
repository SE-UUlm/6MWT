import 'package:six_minute_walk_test/app/app_colors.dart';
import 'package:flutter/material.dart';

/// The app's [AppBar]: walking icon and [title], with the platform back button
/// whenever there is a page to return to.
class AppTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTitleBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  static const double _height = 80;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _height,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      scrolledUnderElevation: 0,
      title: Row(
        spacing: 12,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.circleBlue,
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              size: 34,
              color: Colors.black87,
            ),
          ),
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: actions,
    );
  }
}
