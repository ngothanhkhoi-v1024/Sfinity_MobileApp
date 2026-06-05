import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/group_model.dart';

class DiscoverGroupCard extends StatefulWidget {
  const DiscoverGroupCard({
    super.key,
    required this.group,
    required this.onJoin,
    this.onCancel,
  });

  final GroupModel group;
  final Future<void> Function() onJoin;
  final Future<void> Function()? onCancel;

  @override
  State<DiscoverGroupCard> createState() => _DiscoverGroupCardState();
}

class _DiscoverGroupCardState extends State<DiscoverGroupCard> {
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = AppColors.primaryOf(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _DiscoverAvatar(name: widget.group.name, avatarUrl: widget.group.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.title(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.group.description != null &&
                      widget.group.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.group.description!,
                      style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${widget.group.memberCount} ${l10n.members}',
                    style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _isJoining
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                  )
                : widget.group.myStatus == 'PENDING'
                    ? OutlinedButton(
                        onPressed: () async {
                          if (widget.onCancel == null) return;
                          setState(() => _isJoining = true);
                          try {
                            await widget.onCancel!();
                          } finally {
                            if (mounted) setState(() => _isJoining = false);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.muted(context),
                          side: BorderSide(color: AppColors.border(context)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(l10n.cancel, style: const TextStyle(fontSize: 12)),
                      )
                    : OutlinedButton(
                        onPressed: () async {
                          setState(() => _isJoining = true);
                          try {
                            await widget.onJoin();
                          } finally {
                            if (mounted) setState(() => _isJoining = false);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(color: primary.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(l10n.joinGroup, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverAvatar extends StatelessWidget {
  const _DiscoverAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((s) => s.isNotEmpty ? s[0] : '')
        .join()
        .toUpperCase();

    return CircleAvatar(
      radius: 22,
      backgroundColor: primary.withValues(alpha: 0.08),
      child: Text(
        initials.isNotEmpty ? initials : 'G',
        style: TextStyle(
          color: primary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
