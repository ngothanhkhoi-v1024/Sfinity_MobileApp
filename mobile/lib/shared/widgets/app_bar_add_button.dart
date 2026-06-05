import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppBarAddButton extends StatelessWidget {
  const AppBarAddButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(Icons.add_rounded, color: AppColors.primaryOf(context)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
