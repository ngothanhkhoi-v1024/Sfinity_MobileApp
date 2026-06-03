import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';

class ViewProfilePage extends StatelessWidget {
  const ViewProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: SfinityApp.auth,
      builder: (context, _) {
        final user = SfinityApp.auth.user;
        final avatarUrl = user?['avatar']?.toString();
        final displayName = user?['name']?.toString() ?? '';
        final email = user?['email']?.toString() ?? '';
        final bio = user?['bio']?.toString();

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).viewProfile),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: AppLocalizations.of(context).editProfile,
                onPressed: () => context.push(RouteNames.editProfile),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Center(
                child: Text(
                  displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Center(
                child: Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              // Bio section
              _InfoCard(
                isDark: isDark,
                children: [
                  Text(
                    AppLocalizations.of(context).bio,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bio?.isNotEmpty == true ? bio! : '—',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: bio?.isNotEmpty == true
                          ? (isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1F2937))
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Edit button
              FilledButton.icon(
                onPressed: () => context.push(RouteNames.editProfile),
                icon: const Icon(Icons.edit_outlined),
                label: Text(AppLocalizations.of(context).editProfile),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
