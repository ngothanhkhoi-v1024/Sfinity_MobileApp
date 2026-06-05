import 'package:flutter/material.dart';

import '../../../splash/presentation/widgets/academic_sealion_mascot.dart';

class AssistantFab extends StatelessWidget {
  const AssistantFab({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      elevation: 4,
      shadowColor: cs.primary.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.primary.withValues(alpha: 0.25), width: 1.5),
          ),
          child: const Center(
            child: AcademicSealionMascot(size: 44),
          ),
        ),
      ),
    );
  }
}
