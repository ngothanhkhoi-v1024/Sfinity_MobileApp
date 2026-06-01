import 'package:flutter/material.dart';
import '../../data/models/friend_model.dart';

class UserSearchTile extends StatelessWidget {
  const UserSearchTile({
    super.key,
    required this.user,
    required this.isSent,
    required this.isAccepted,
    required this.onTap,
    required this.onAdd,
    required this.onCancel,
  });

  final FriendUser user;
  final bool isSent;
  final bool isAccepted;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
            ? NetworkImage(user.avatar!)
            : null,
        backgroundColor: cs.primaryContainer,
        child: user.avatar == null || user.avatar!.isEmpty
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: user.email != null ? Text(user.email!) : null,
      trailing: isAccepted
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 12, color: cs.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Bạn bè',
                    style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : isSent
              ? OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Hủy',
                    style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.bold),
                  ),
                )
              : FilledButton.tonal(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Kết bạn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
    );
  }
}
