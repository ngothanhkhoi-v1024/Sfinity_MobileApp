import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_button.dart';
import 'place_tag_chips.dart';
import 'places_header_panel.dart';
import 'places_search_field.dart';

class PlacesMapToolbar extends StatelessWidget {
  const PlacesMapToolbar({
    super.key,
    required this.communityMode,
    required this.listView,
    required this.onCommunityChanged,
    required this.onViewChanged,
    required this.searchController,
    required this.onSearchChanged,
    required this.filterTags,
    required this.onFilterChanged,
    required this.onFilterApply,
    required this.studyNearMeLoading,
    required this.onStudyNearMe,
    this.highlightBanner,
    this.locationHint,
    this.mapOverlay = true,
  });

  final bool communityMode;
  final bool listView;
  final ValueChanged<bool> onCommunityChanged;
  final ValueChanged<bool> onViewChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Set<String> filterTags;
  final ValueChanged<Set<String>> onFilterChanged;
  final VoidCallback onFilterApply;
  final bool studyNearMeLoading;
  final VoidCallback onStudyNearMe;
  final Widget? highlightBanner;
  final String? locationHint;
  final bool mapOverlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = AppColors.isDark(context);
    final surface = AppColors.card(context).withValues(alpha: mapOverlay ? (isDark ? 0.94 : 0.96) : 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, mapOverlay ? 4 : 0, 12, mapOverlay ? 6 : 0),
      child: Material(
        color: surface,
        elevation: mapOverlay ? (isDark ? 0 : 3) : 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(mapOverlay ? 18 : 0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(mapOverlay ? 18 : 0),
            border: Border.all(
              color: AppColors.border(context),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlacesHeaderPanel(
                communityMode: communityMode,
                listView: listView,
                onCommunityChanged: onCommunityChanged,
                onViewChanged: onViewChanged,
                embedded: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: PlacesSearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  onSubmitted: onSearchChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Row(
                  children: [
                    StudyNearMeButton(
                      compact: true,
                      loading: studyNearMeLoading,
                      onPressed: onStudyNearMe,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.filter_list_rounded,
                      size: 16,
                      color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.filter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              PlaceTagFilterBar(
                selected: filterTags,
                onChanged: onFilterChanged,
                onApply: onFilterApply,
              ),
              const SizedBox(height: 6),
              if (highlightBanner != null) highlightBanner!,
              if (locationHint != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: _LocationHintChip(message: locationHint!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationHintChip extends StatelessWidget {
  const _LocationHintChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, height: 1.3, color: Color(0xFFB45309)),
            ),
          ),
        ],
      ),
    );
  }
}
