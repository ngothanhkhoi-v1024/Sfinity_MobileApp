import 'package:flutter/material.dart';
import '../../../../core/i18n/app_text.dart';
import '../../data/models/friend_model.dart';
import '../controllers/friendship_controller.dart';

class UserProfileBottomSheet extends StatefulWidget {
  const UserProfileBottomSheet({
    super.key,
    required this.user,
    required this.ctrl,
  });

  final FriendUser user;
  final FriendshipController ctrl;

  static void show(
    BuildContext context,
    FriendUser user,
    FriendshipController ctrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => UserProfileBottomSheet(user: user, ctrl: ctrl),
    );
  }

  @override
  State<UserProfileBottomSheet> createState() => _UserProfileBottomSheetState();
}

class _UserProfileBottomSheetState extends State<UserProfileBottomSheet> {
  bool _isLoading = false;
  late String? _friendshipStatus;
  late String? _friendshipId;

  @override
  void initState() {
    super.initState();
    _determineFriendship();
  }

  void _determineFriendship() {
    // 1. Dùng trạng thái truyền vào trước
    _friendshipStatus = widget.user.friendshipStatus;
    _friendshipId = widget.user.friendshipId;

    // 2. Nếu trống, kiểm tra xem có trong danh sách bạn bè đã tải không
    final friendsList = widget.ctrl.friends;
    final friendMatch = friendsList.firstWhere(
      (f) => f.user.id == widget.user.id,
      orElse: () => const FriendModel(
        friendshipId: '',
        user: FriendUser(id: '', name: ''),
      ),
    );
    if (friendMatch.user.id.isNotEmpty) {
      _friendshipStatus = 'ACCEPTED';
      _friendshipId = friendMatch.friendshipId;
      return;
    }

    // 3. Hoặc kiểm tra xem có trong lời mời đang chờ (người khác gửi cho mình) không
    final pendingRequests = widget.ctrl.pendingRequests;
    final requestMatch = pendingRequests.firstWhere(
      (r) => r.requester.id == widget.user.id,
      orElse: () => PendingRequest(
        id: '',
        requester: const FriendUser(id: '', name: ''),
        createdAt: DateTime.now(),
      ),
    );
    if (requestMatch.requester.id.isNotEmpty) {
      _friendshipStatus = 'PENDING_INCOMING';
      _friendshipId = requestMatch.id;
      return;
    }
  }

  List<Color> _gradientForName(String name) {
    final palettes = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFEC4899), const Color(0xFFF97316)],
      [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
    ];
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % palettes.length : 0;
    return palettes[idx];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = widget.user;
    final colors = _gradientForName(user.name);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elegant Profile Header Card with Gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundImage:
                        user.avatar != null && user.avatar!.isNotEmpty
                        ? NetworkImage(user.avatar!)
                        : null,
                    backgroundColor: Colors.white,
                    child: user.avatar == null || user.avatar!.isEmpty
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colors[0],
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                if (user.email != null)
                  Text(
                    user.email!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons based on Friendship status
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: _buildActionButtons(cs),
                ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme cs) {
    final l10n = context.l10n;

    if (_friendshipStatus == 'ACCEPTED') {
      return OutlinedButton.icon(
        onPressed: () async {
          if (_friendshipId == null) return;
          setState(() => _isLoading = true);
          final success = await widget.ctrl.unfriend(_friendshipId!);
          if (mounted) setState(() => _isLoading = false);
          if (success) {
            setState(() {
              _friendshipStatus = null;
              _friendshipId = null;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.friendRequestSuccess)),
              );
            }
          }
        },
        icon: Icon(Icons.person_remove_outlined, color: cs.error),
        label: Text(l10n.unfriend, style: TextStyle(color: cs.error)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }

    if (_friendshipStatus == 'PENDING_INCOMING') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                if (_friendshipId == null) return;
                setState(() => _isLoading = true);
                final success = await widget.ctrl.respondRequest(
                  _friendshipId!,
                  false,
                );
                if (mounted) setState(() => _isLoading = false);
                if (success) {
                  setState(() {
                    _friendshipStatus = null;
                    _friendshipId = null;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.declineInvite),
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.close, color: cs.error),
              label: Text(l10n.cancelRequest, style: TextStyle(color: cs.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                if (_friendshipId == null) return;
                setState(() => _isLoading = true);
                final success = await widget.ctrl.respondRequest(
                  _friendshipId!,
                  true,
                );
                if (mounted) setState(() => _isLoading = false);
                if (success) {
                  setState(() {
                    _friendshipStatus = 'ACCEPTED';
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.friendRequestSuccess),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    if (_friendshipStatus == 'PENDING') {
      return OutlinedButton.icon(
        onPressed: () async {
          setState(() => _isLoading = true);
          final target = _friendshipId ?? widget.user.id;
          final success = await widget.ctrl.unfriend(target);
          if (mounted) setState(() => _isLoading = false);
          if (success) {
            setState(() {
              _friendshipStatus = null;
              _friendshipId = null;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.cancelRequest)),
              );
            }
          }
        },
        icon: Icon(Icons.close, color: cs.error),
        label: Text(l10n.cancel, style: TextStyle(color: cs.error)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }

    // Default: Not friends yet
    return FilledButton.icon(
      onPressed: () async {
        setState(() => _isLoading = true);
        final success = await widget.ctrl.sendRequest(widget.user.id);
        if (mounted) setState(() => _isLoading = false);
        if (success) {
          setState(() {
            _friendshipStatus = 'PENDING';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.friendRequestSent)),
            );
          }
        }
      },
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: Text(l10n.addFriends),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
