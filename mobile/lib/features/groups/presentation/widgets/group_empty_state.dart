import 'package:flutter/material.dart';
import '../../../../core/i18n/app_text.dart';

class GroupEmptyState extends StatelessWidget {
  const GroupEmptyState({
    super.key,
    required this.onCreateGroup,
    this.canCreateGroup = true,
  });

  final VoidCallback onCreateGroup;
  final bool canCreateGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group_outlined, size: 56, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text(l10n.noGroupsYet, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              canCreateGroup ? l10n.createGroupHint : l10n.limitCreateGroup,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateGroup,
              icon: Icon(
                canCreateGroup ? Icons.add : Icons.workspace_premium_outlined,
              ),
              label: Text(l10n.createGroupBtn),
            ),
          ],
        ),
      ),
    );
  }
}
