import 'package:flutter/material.dart';

import '../../../../app.dart';
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
        final gender = user?['gender']?.toString();
        final birthDate = user?['birthDate']?.toString();
        final address = user?['address']?.toString();

        String formattedBirthDate;
        if (birthDate != null && birthDate.isNotEmpty) {
          final parts = birthDate.split('-');
          if (parts.length == 3) {
            formattedBirthDate = '${parts[2]}/${parts[1]}/${parts[0]}';
          } else {
            formattedBirthDate = birthDate;
          }
        } else {
          formattedBirthDate = '';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).viewProfile),
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
                  displayName.isNotEmpty ? displayName : '—',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Center(
                child: Text(
                  email.isNotEmpty ? email : '—',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Info cards
              _InfoCard(isDark: isDark, children: [
                _InfoRow(
                  icon: Icons.wc_outlined,
                  label: 'Giới tính',
                  value: gender != null && gender.isNotEmpty ? gender : '—',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Ngày sinh',
                  value: formattedBirthDate.isNotEmpty ? formattedBirthDate : '—',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Địa chỉ',
                  value: address != null && address.isNotEmpty ? address : '—',
                  isDark: isDark,
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = value != '—'
        ? (isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1F2937))
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
