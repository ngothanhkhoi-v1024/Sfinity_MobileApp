import 'package:flutter/material.dart';
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
    final user = friend.user;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              const PopupMenuItem(value: 'unfriend', child: Text('Hủy kết bạn')),
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
    final cs = Theme.of(context).colorScheme;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.primaryContainer,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
