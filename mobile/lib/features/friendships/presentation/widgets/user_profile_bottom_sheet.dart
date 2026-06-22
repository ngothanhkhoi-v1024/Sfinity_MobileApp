import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/widgets/vip_limit_dialogs.dart';
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

    final sentRequests = widget.ctrl.sentRequests;
    final sentMatch = sentRequests.firstWhere(
      (r) => r.addressee.id == widget.user.id,
      orElse: () => SentRequest(
        id: '',
        addressee: const FriendUser(id: '', name: ''),
        createdAt: DateTime.now(),
      ),
    );
    if (sentMatch.addressee.id.isNotEmpty) {
      _friendshipStatus = 'PENDING';
      _friendshipId = sentMatch.id;
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
          _ProfileInfoCard(user: user),
          const SizedBox(height: 20),

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
      return Row(
        children: [
          Expanded(
            child: _buildViewProfileButton(cs),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
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
            ),
          ),
        ],
      );
    }

    if (_friendshipStatus == 'PENDING_INCOMING') {
      return Row(
        children: [
          Expanded(
            child: _buildViewProfileButton(cs),
          ),
          const SizedBox(width: 10),
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
              label: Text(l10n.decline, style: TextStyle(color: cs.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                } else if (mounted) {
                  VipLimitDialogs.handleFriendshipError(context, widget.ctrl.error);
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
      return Row(
        children: [
          Expanded(
            child: _buildViewProfileButton(cs),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
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
            ),
          ),
        ],
      );
    }

    // Default: Not friends yet
    return Row(
      children: [
        Expanded(
          child: _buildViewProfileButton(cs),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
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
              } else if (mounted) {
                VipLimitDialogs.handleFriendshipError(context, widget.ctrl.error);
              }
            },
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(l10n.addFriends),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewProfileButton(ColorScheme cs) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        context.push(
          RouteNames.viewProfile,
          extra: widget.user,
        );
      },
      icon: const Icon(Icons.visibility_outlined),
      label: Text(context.l10n.viewProfile),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.user});

  final FriendUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileInfoRow(
            icon: Icons.wc_outlined,
            label: context.l10n.gender,
            value: _displayValue(user.gender),
          ),
          const SizedBox(height: 14),
          _ProfileInfoRow(
            icon: Icons.cake_outlined,
            label: context.l10n.dateOfBirth,
            value: _formatBirthDate(user.birthDate),
          ),
          const SizedBox(height: 14),
          _ProfileInfoRow(
            icon: Icons.location_on_outlined,
            label: context.l10n.address,
            value: _displayValue(user.address),
          ),
        ],
      ),
    );
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String _formatBirthDate(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '—';
    final parts = trimmed.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return trimmed;
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
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
                  color: value != '—'
                      ? (isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1F2937))
                      : theme.colorScheme.onSurfaceVariant,
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
