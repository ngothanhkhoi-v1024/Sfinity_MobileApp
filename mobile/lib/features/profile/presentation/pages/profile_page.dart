import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: SfinityApp.auth,
      builder: (context, _) {
        final user = SfinityApp.auth.user;
        final avatarUrl = user?['avatar']?.toString();
        final displayName = user?['name']?.toString() ?? '';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text((displayName.isNotEmpty ? displayName : 'U')[0].toUpperCase())
                  : null,
            ),
            const SizedBox(height: 12),
            Text(displayName, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            Text(user?['email']?.toString() ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _buildMenuTile(
              context,
              icon: Icons.person_outlined,
              title: context.l10n.viewProfile,
              onTap: () => context.push(RouteNames.viewProfile),
              isDark: isDark,
            ),
            _buildMenuTile(
              context,
              icon: Icons.edit_outlined,
              title: context.l10n.editProfile,
              onTap: () => context.push(RouteNames.editProfile),
              isDark: isDark,
            ),
            _buildMenuTile(
              context,
              icon: Icons.lock_outline,
              title: context.l10n.changePassword,
              onTap: () => context.push(RouteNames.changePassword),
              isDark: isDark,
            ),
            _buildMenuTile(
              context,
              icon: Icons.notifications_outlined,
              title: context.l10n.notifications,
              onTap: () => context.push(RouteNames.notifications),
              isDark: isDark,
            ),
            _buildMenuTile(
              context,
              icon: Icons.article_outlined,
              title: context.l10n.myPosts,
              onTap: () => context.push(RouteNames.documentList),
              isDark: isDark,
            ),
            _buildMenuTile(
              context,
              icon: Icons.feedback_outlined,
              title: context.l10n.feedback,
              onTap: () => context.push(RouteNames.feedback),
              isDark: isDark,
            ),
            _buildMenuTile(
              context,
              icon: Icons.flag_outlined,
              title: context.l10n.reportViolation,
              onTap: () => context.push(RouteNames.report),
              isDark: isDark,
            ),
            _buildMenuTile(
              context,
              icon: Icons.settings_outlined,
              title: context.l10n.settings,
              onTap: () => context.push(RouteNames.settings),
              isDark: isDark,
            ),
            const Divider(),
            _buildMenuTile(
              context,
              icon: Icons.logout,
              title: context.l10n.signOut,
              onTap: () async {
                await SfinityApp.auth.logout();
                if (context.mounted) context.go(RouteNames.login);
              },
              isDark: isDark,
              isLogout: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
       child: ListTile(
         leading: Icon(
           icon,
           color: isLogout
               ? Theme.of(context).colorScheme.error
               : (isDark
                   ? const Color(0xFFF2F2F2)
                   : const Color(0xFF1F2937)),
         ),
         title: Text(
           title,
           style: TextStyle(
             color: isLogout
                 ? Theme.of(context).colorScheme.error
                 : (isDark
                     ? const Color(0xFFF2F2F2)
                     : const Color(0xFF1F2937)),
           ),
         ),
         onTap: onTap,
       ),
     );
   }
}
