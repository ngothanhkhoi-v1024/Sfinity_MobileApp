import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/friend_model.dart';

class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.friend,
    this.onTap,
    this.trailing,
  });

  final FriendModel friend;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final user = friend.user;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _Avatar(name: user.name, avatarUrl: user.avatar, size: 46),
      title: Text(
        user.name,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: user.email != null
          ? Text(
              user.email!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            )
          : null,
      trailing: trailing ??
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
            onSelected: (_) {},
            itemBuilder: (_) => [
              PopupMenuItem(value: 'unfriend', child: Text(l10n.unfriend)),
            ],
          ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.avatarUrl, this.size = 40});
  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    final primary = AppColors.primaryOf(context);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: primary.withValues(alpha: 0.08),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
