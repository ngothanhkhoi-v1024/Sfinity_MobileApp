import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class ExploreTopUsersSection extends StatelessWidget {
  const ExploreTopUsersSection({
    super.key,
    required this.users,
    required this.onUserTap,
  });

  final List<Map<String, dynamic>> users;
  final ValueChanged<Map<String, dynamic>> onUserTap;

  static const _accent = AppColors.secondary;
  static const _accentDeep = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (users.isEmpty) return const SizedBox.shrink();

    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A1A12), const Color(0xFF1A1A1A)]
              : [const Color(0xFFFFF7ED), Colors.white],
        ),
        border: Border.all(
          color: _accent.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: isDark ? 0.1 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, _accentDeep],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.topUsersTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title(context),
                      ),
                    ),
                    Text(
                      l10n.topUsersSubtitle,
                      style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < users.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _TopUserRow(
              user: users[i],
              rank: (users[i]['rank'] as num?)?.toInt() ?? i + 1,
              onTap: () => onUserTap(users[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopUserRow extends StatelessWidget {
  const _TopUserRow({
    required this.user,
    required this.rank,
    required this.onTap,
  });

  final Map<String, dynamic> user;
  final int rank;
  final VoidCallback onTap;

  Color _rankColor() {
    return switch (rank) {
      1 => const Color(0xFFFFB300),
      2 => const Color(0xFF9E9E9E),
      3 => const Color(0xFFCD7F32),
      _ => ExploreTopUsersSection._accentDeep.withValues(alpha: 0.75),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = user['name']?.toString() ?? '';
    final avatar = user['avatar']?.toString();
    final score = (user['score'] as num?)?.toInt() ?? 0;
    final docs = (user['documentsCount'] as num?)?.toInt() ?? 0;
    final places = (user['placesCount'] as num?)?.toInt() ?? 0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isDark = AppColors.isDark(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : ExploreTopUsersSection._accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: rank <= 3
                  ? _rankColor().withValues(alpha: 0.35)
                  : AppColors.border(context),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _rankColor().withValues(alpha: isDark ? 0.25 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _rankColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: ExploreTopUsersSection._accent.withValues(alpha: 0.15),
                  backgroundImage:
                      avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar == null || avatar.isEmpty
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ExploreTopUsersSection._accentDeep,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.title(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.topUsersContributions(docs: docs, places: places),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ExploreTopUsersSection._accent.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.topUsersScore(score),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ExploreTopUsersSection._accentDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
