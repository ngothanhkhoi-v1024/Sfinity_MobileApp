import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);

    return AnimatedBuilder(
      animation: SfinityApp.auth,
      builder: (context, _) {
        final user = SfinityApp.auth.user;
        final avatarUrl = user?['avatar']?.toString();
        final displayName = user?['name']?.toString() ?? '';
        final email = user?['email']?.toString() ?? '';
        final authProvider = user?['authProvider']?.toString() ?? 'local';
        final hasPassword = user?['hasPassword'] as bool? ?? false;
        final canChangeOrSetPassword = hasPassword || authProvider == 'google' || authProvider == 'facebook';

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          children: [
            _ProfileHeader(
              displayName: displayName,
              email: email,
              avatarUrl: avatarUrl,
              primary: primary,
              isDark: isDark,
              onViewProfile: () => context.push(RouteNames.viewProfile),
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: context.l10n.account,
              isDark: isDark,
              children: [
                _ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  iconColor: primary,
                  title: context.l10n.viewProfile,
                  onTap: () => context.push(RouteNames.viewProfile),
                  isDark: isDark,
                ),
                if (isLocalUser)
                  _ProfileMenuItem(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: hasPassword ? context.l10n.changePassword : context.l10n.setPassword,
                    onTap: () => context.push(RouteNames.changePassword),
                    isDark: isDark,
                  ),
              ],
            ),
            _ProfileSection(
              title: context.l10n.studyGroups,
              isDark: isDark,
              children: [
                _ProfileMenuItem(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: context.l10n.notifications,
                  onTap: () => context.push(RouteNames.notifications),
                  isDark: isDark,
                ),
                _ProfileMenuItem(
                  icon: Icons.article_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: context.l10n.myPosts,
                  onTap: () => context.push(RouteNames.myDocuments),
                  isDark: isDark,
                ),
              ],
            ),
            _ProfileSection(
              title: context.l10n.feedback,
              isDark: isDark,
              children: [
                _ProfileMenuItem(
                  icon: Icons.feedback_outlined,
                  iconColor: const Color(0xFF06B6D4),
                  title: context.l10n.feedback,
                  onTap: () => context.push(RouteNames.feedback),
                  isDark: isDark,
                ),
                _ProfileMenuItem(
                  icon: Icons.flag_outlined,
                  iconColor: const Color(0xFFEF4444),
                  title: context.l10n.reportViolation,
                  onTap: () => context.push(RouteNames.report),
                  isDark: isDark,
                ),
              ],
            ),
            _ProfileSection(
              title: context.l10n.settings,
              isDark: isDark,
              children: [
                _ProfileMenuItem(
                  icon: Icons.settings_outlined,
                  iconColor: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                  title: context.l10n.settings,
                  onTap: () => context.push(RouteNames.settings),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ProfileLogoutCard(
              title: context.l10n.signOut,
              onTap: () async {
                await SfinityApp.auth.logout();
                if (context.mounted) context.go(RouteNames.login);
              },
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.primary,
    required this.isDark,
    required this.onViewProfile,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final Color primary;
  final bool isDark;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final initial = (displayName.isNotEmpty ? displayName : 'U')[0].toUpperCase();

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewProfile,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.border(context),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                decoration: BoxDecoration(
                  gradient: AppColors.brandHeader(context),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: primary.withValues(alpha: 0.15),
                        backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                        child: hasAvatar
                            ? null
                            : Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isNotEmpty ? displayName : 'Người dùng',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.muted(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.viewProfile,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.isDark,
    required this.children,
  });

  final String title;
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.muted(context),
              ),
            ),
          ),
          Material(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.border(context),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: AppColors.divider(context),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLogoutCard extends StatelessWidget {
  const _ProfileLogoutCard({
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  final String title;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: error.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 20, color: error),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: error,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
