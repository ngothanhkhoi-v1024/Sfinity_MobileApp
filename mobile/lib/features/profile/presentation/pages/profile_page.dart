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
    final primary = AppColors.primaryOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        SfinityApp.auth,
        SfinityApp.assistantFabPositionManager,
      ]),
      builder: (context, _) {
        final assistantFabVisible = SfinityApp.assistantFabPositionManager.visible;
        final user = SfinityApp.auth.user;
        final avatarUrl = user?['avatar']?.toString();
        final displayName = user?['name']?.toString() ?? '';
        final email = user?['email']?.toString() ?? '';
        final authProvider = user?['authProvider']?.toString() ?? 'local';
        final hasPassword = user?['hasPassword'] as bool? ?? false;
        final canChangeOrSetPassword =
            hasPassword || authProvider == 'google' || authProvider == 'facebook';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _ProfileHeader(
              displayName: displayName,
              email: email,
              avatarUrl: avatarUrl,
              primary: primary,
              onViewProfile: () => context.push(RouteNames.viewProfile),
            ),
            const SizedBox(height: 20),
            _ProfileSection(
              title: context.l10n.account,
              children: [
                _ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: context.l10n.viewProfile,
                  onTap: () => context.push(RouteNames.viewProfile),
                ),
                if (canChangeOrSetPassword)
                  _ProfileMenuItem(
                    icon: Icons.lock_outline_rounded,
                    title: hasPassword
                        ? context.l10n.changePassword
                        : context.l10n.setPassword,
                    onTap: () => context.push(RouteNames.changePassword),
                  ),
              ],
            ),
            _ProfileSection(
              title: context.l10n.studyGroups,
              children: [
                _ProfileMenuItem(
                  icon: Icons.workspace_premium_outlined,
                  title: context.l10n.upgradeVip,
                  onTap: () => context.push(RouteNames.subscription),
                ),
                _ProfileMenuItem(
                  icon: Icons.notifications_outlined,
                  title: context.l10n.notifications,
                  onTap: () => context.push(RouteNames.notifications),
                ),
                _ProfileMenuItem(
                  icon: Icons.bookmark_outline_rounded,
                  title: context.l10n.saved,
                  onTap: () => context.push(RouteNames.favorites),
                ),
                _ProfileMenuItem(
                  icon: Icons.article_outlined,
                  title: context.l10n.myPosts,
                  onTap: () => context.push(RouteNames.myDocuments),
                ),
                _ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  title: context.l10n.myPlaces,
                  onTap: () => context.push(RouteNames.myPlaces),
                ),
              ],
            ),
            _ProfileSection(
              title: context.l10n.feedback,
              children: [
                _ProfileMenuItem(
                  icon: Icons.feedback_outlined,
                  title: context.l10n.feedback,
                  onTap: () => context.push(RouteNames.feedback),
                ),
                _ProfileMenuItem(
                  icon: Icons.flag_outlined,
                  title: context.l10n.reportViolation,
                  onTap: () => context.push(RouteNames.report),
                ),
              ],
            ),
            _ProfileSection(
              title: context.l10n.settings,
              children: [
                _ProfileSwitchItem(
                  icon: Icons.smart_toy_outlined,
                  title: context.l10n.assistantShowFab,
                  subtitle: context.l10n.assistantShowFabSubtitle,
                  value: assistantFabVisible,
                  onChanged: (value) =>
                      SfinityApp.assistantFabPositionManager.setVisible(value),
                ),
                _ProfileMenuItem(
                  icon: Icons.settings_outlined,
                  title: context.l10n.settings,
                  onTap: () => context.push(RouteNames.settings),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _ProfileLogoutButton(
              title: context.l10n.signOut,
              onTap: () async {
                await SfinityApp.auth.logout();
                if (context.mounted) context.go(RouteNames.login);
              },
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
    required this.onViewProfile,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final Color primary;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final initial = (displayName.isNotEmpty ? displayName : 'U')[0].toUpperCase();

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onViewProfile,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: primary.withValues(alpha: 0.08),
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                child: hasAvatar
                    ? null
                    : Text(
                        initial,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primary,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: AppColors.title(context),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
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
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted(context)),
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
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted(context),
              ),
            ),
          ),
          Material(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border(context)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1)
                      Divider(
                        height: 1,
                        indent: 48,
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

class _ProfileSwitchItem extends StatelessWidget {
  const _ProfileSwitchItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.title(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted(context),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.muted(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.title(context),
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLogoutButton extends StatelessWidget {
  const _ProfileLogoutButton({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: error.withValues(alpha: 0.85)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: error.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
