import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final Map<String, dynamic>? user;
  final double radius;

  const UserAvatar({super.key, this.user, this.radius = 48});

  String _initial() {
    final name = user?['full_name'] as String?;
    if (name == null || name.isEmpty) return 'N';
    return name[0].toUpperCase();
  }

  Widget _initialWidget() {
    return Text(
      _initial(),
      style: TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = user?['avatar'] as String?;
    final hasAvatar = (avatar ?? '').isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.lightBlue,
      child: hasAvatar
          ? ClipOval(
              child: Image.network(
                ApiConfig.avatarUrl(avatar!),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initialWidget(),
              ),
            )
          : _initialWidget(),
    );
  }
}
