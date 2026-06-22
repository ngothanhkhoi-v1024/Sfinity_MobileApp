import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/widgets/vip_limit_dialogs.dart';
import '../../../friendships/data/models/friend_model.dart';
import '../../../friendships/presentation/controllers/friendship_controller.dart';

final Map<String, Uint8List> _avatarCache = {};

Future<Uint8List?> _tryFetchAvatar(String url) async {
  if (_avatarCache.containsKey(url)) {
    return _avatarCache[url];
  }
  try {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.data == null || response.data!.isEmpty) return null;
    final bytes = Uint8List.fromList(response.data!);
    _avatarCache[url] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

class ViewProfilePage extends StatelessWidget {
  const ViewProfilePage({super.key, this.profileUser});

  final FriendUser? profileUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isViewingFriend = profileUser != null;

    return AnimatedBuilder(
      animation: SfinityApp.auth,
      builder: (context, _) {
        final user = SfinityApp.auth.user;
        final avatarUrl = isViewingFriend
            ? profileUser!.avatar
            : user?['avatar']?.toString();
        final displayName = isViewingFriend
            ? profileUser!.name
            : user?['name']?.toString() ?? '';
        final email = isViewingFriend
            ? profileUser!.email?.toString() ?? ''
            : user?['email']?.toString() ?? '';
        final gender = isViewingFriend
            ? profileUser!.gender?.toString()
            : user?['gender']?.toString();
        final birthDate = isViewingFriend
            ? profileUser!.birthDate?.toString()
            : user?['birthDate']?.toString();
        final address = isViewingFriend
            ? profileUser!.address?.toString()
            : user?['address']?.toString();

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
            actions: isViewingFriend
                ? null
                : [
                    IconButton(
                      onPressed: () => context.push(RouteNames.editProfile),
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: AppLocalizations.of(context).editProfile,
                    ),
                  ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar
              Center(
                child: _AvatarWidget(
                  avatarUrl: avatarUrl,
                  displayName: displayName,
                  size: 112,
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
                  context: context,
                  icon: Icons.wc_outlined,
                  label: context.l10n.gender,
                  value: gender != null && gender.isNotEmpty ? gender : '—',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  context: context,
                  icon: Icons.cake_outlined,
                  label: context.l10n.dateOfBirth,
                  value: formattedBirthDate.isNotEmpty ? formattedBirthDate : '—',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  context: context,
                  icon: Icons.location_on_outlined,
                  label: context.l10n.address,
                  value: address != null && address.isNotEmpty ? address : '—',
                  isDark: isDark,
                ),
              ]),
              if (isViewingFriend) ...[
                const SizedBox(height: 24),
                _FriendActionSection(user: profileUser!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AvatarWidget extends StatefulWidget {
  const _AvatarWidget({
    required this.avatarUrl,
    required this.displayName,
    required this.size,
  });

  final String? avatarUrl;
  final String displayName;
  final double size;

  @override
  State<_AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<_AvatarWidget> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.avatarUrl == null || widget.avatarUrl!.isEmpty) {
      setState(() => _bytes = null);
      return;
    }
    setState(() {
      _loading = true;
      _bytes = _avatarCache[widget.avatarUrl];
    });
    if (_bytes != null) {
      setState(() => _loading = false);
      return;
    }
    final bytes = await _tryFetchAvatar(widget.avatarUrl!);
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (_loading && _bytes == null) {
      content = Center(
        child: SizedBox(
          width: widget.size * 0.4,
          height: widget.size * 0.4,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
      );
    } else {
      content = _buildPlaceholder(theme);
    }

    return ClipOval(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: content,
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          widget.displayName.isNotEmpty
              ? widget.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: widget.size * 0.36,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.context,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final BuildContext context;
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

class _FriendActionSection extends StatefulWidget {
  const _FriendActionSection({required this.user});

  final FriendUser user;

  @override
  State<_FriendActionSection> createState() => _FriendActionSectionState();
}

class _FriendActionSectionState extends State<_FriendActionSection> {
  late final FriendshipController _ctrl;
  bool _isLoading = false;
  String? _friendshipStatus;
  String? _friendshipId;

  @override
  void initState() {
    super.initState();
    _ctrl = SfinityApp.friendshipController;
    _ctrl.addListener(_syncFriendshipState);
    _primeData();
    _syncFriendshipState();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_syncFriendshipState);
    super.dispose();
  }

  void _primeData() {
    _ctrl.loadFriends();
    _ctrl.loadPendingRequests();
    _ctrl.loadSentRequests();
  }

  void _syncFriendshipState() {
    String? nextStatus = widget.user.friendshipStatus;
    String? nextId = widget.user.friendshipId;

    final friendMatch = _ctrl.friends.where((f) => f.user.id == widget.user.id);
    if (friendMatch.isNotEmpty) {
      final friend = friendMatch.first;
      nextStatus = 'ACCEPTED';
      nextId = friend.friendshipId;
    } else {
      final incoming = _ctrl.pendingRequests.where(
        (r) => r.requester.id == widget.user.id,
      );
      if (incoming.isNotEmpty) {
        nextStatus = 'PENDING_INCOMING';
        nextId = incoming.first.id;
      } else {
        final sent = _ctrl.sentRequests.where(
          (r) => r.addressee.id == widget.user.id,
        );
        if (sent.isNotEmpty) {
          nextStatus = 'PENDING';
          nextId = sent.first.id;
        } else {
          nextStatus = null;
          nextId = null;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _friendshipStatus = nextStatus;
      _friendshipId = nextId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendshipStatus == 'ACCEPTED') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _unfriend,
          icon: Icon(Icons.person_remove_outlined, color: cs.error),
          label: Text(
            context.l10n.unfriend,
            style: TextStyle(color: cs.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    if (_friendshipStatus == 'PENDING') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _cancelRequest,
          icon: Icon(Icons.close, color: cs.error),
          label: Text(
            context.l10n.cancel,
            style: TextStyle(color: cs.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    if (_friendshipStatus == 'PENDING_INCOMING') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _declineIncoming,
              icon: Icon(Icons.close, color: cs.error),
              label: Text(
                context.l10n.cancelRequest,
                style: TextStyle(color: cs.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _acceptIncoming,
              icon: const Icon(Icons.check),
              label: Text(context.l10n.accept),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _sendRequest,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(context.l10n.addFriends),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _sendRequest() async {
    setState(() => _isLoading = true);
    final ok = await _ctrl.sendRequest(widget.user.id);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.friendRequestSent)),
      );
      _syncFriendshipState();
    } else {
      VipLimitDialogs.handleFriendshipError(context, _ctrl.error);
    }
  }

  Future<void> _cancelRequest() async {
    final target = _friendshipId ?? widget.user.id;
    setState(() => _isLoading = true);
    final ok = await _ctrl.unfriend(target);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cancelRequest)),
      );
      _syncFriendshipState();
    }
  }

  Future<void> _unfriend() async {
    if (_friendshipId == null) return;
    setState(() => _isLoading = true);
    final ok = await _ctrl.unfriend(_friendshipId!);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.unfriend)),
      );
      _syncFriendshipState();
    }
  }

  Future<void> _declineIncoming() async {
    if (_friendshipId == null) return;
    setState(() => _isLoading = true);
    final ok = await _ctrl.respondRequest(_friendshipId!, false);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.declineInvite)),
      );
      _syncFriendshipState();
    }
  }

  Future<void> _acceptIncoming() async {
    if (_friendshipId == null) return;
    setState(() => _isLoading = true);
    final ok = await _ctrl.respondRequest(_friendshipId!, true);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.friendRequestSuccess)),
      );
      _syncFriendshipState();
    }
  }
}
