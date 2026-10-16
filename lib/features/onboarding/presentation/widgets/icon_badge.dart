import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/config_icons.dart';

class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key});

  final String? icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: AppColors.blush,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.surface, width: 4),
      boxShadow: AppShadows.card,
    ),
    child: Icon(iconFor(icon), color: AppColors.primary, size: 28),
  );
}
