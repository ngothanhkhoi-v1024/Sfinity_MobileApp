import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_button.dart';
import 'place_tag_chips.dart';
import 'places_header_panel.dart';
import 'places_search_field.dart';

class PlacesMapToolbar extends StatefulWidget {
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
    required this.studyNearMeLoading,
    required this.onStudyNearMe,
    this.highlightBanner,
    this.locationHint,
    this.mapOverlay = true,
    this.filterCount = 0,
  });

  final bool communityMode;
  final bool listView;
  final ValueChanged<bool> onCommunityChanged;
  final ValueChanged<bool> onViewChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Set<String> filterTags;
  final ValueChanged<Set<String>> onFilterChanged;
  final bool studyNearMeLoading;
  final VoidCallback onStudyNearMe;
  final Widget? highlightBanner;
  final String? locationHint;
  final bool mapOverlay;
  final int filterCount;

  @override
  State<PlacesMapToolbar> createState() => _PlacesMapToolbarState();
}

class _PlacesMapToolbarState extends State<PlacesMapToolbar> {
  bool _filtersExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = AppColors.isDark(context);
    final surface = AppColors.card(context).withValues(alpha: widget.mapOverlay ? (isDark ? 0.94 : 0.96) : 1);
    final primary = theme.colorScheme.primary;
    final activeCount = widget.filterCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, widget.mapOverlay ? 4 : 0, 12, widget.mapOverlay ? 6 : 0),
      child: Material(
        color: surface,
        elevation: widget.mapOverlay ? (isDark ? 0 : 3) : 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(widget.mapOverlay ? 18 : 0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.mapOverlay ? 18 : 0),
            border: Border.all(
              color: AppColors.border(context),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlacesHeaderPanel(
                communityMode: widget.communityMode,
                listView: widget.listView,
                onCommunityChanged: widget.onCommunityChanged,
                onViewChanged: widget.onViewChanged,
                embedded: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: PlacesSearchField(
                  controller: widget.searchController,
                  onChanged: widget.onSearchChanged,
                  onSubmitted: widget.onSearchChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Row(
                  children: [
                    StudyNearMeButton(
                      compact: true,
                      loading: widget.studyNearMeLoading,
                      onPressed: widget.onStudyNearMe,
                    ),
                    const Spacer(),
                    Material(
                      color: activeCount > 0
                          ? primary.withValues(alpha: isDark ? 0.22 : 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _filtersExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.tune_rounded,
                                size: 18,
                                color: activeCount > 0 ? primary : AppColors.muted(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activeCount > 0
                                    ? l10n.activeFilters(activeCount)
                                    : l10n.filterAmenities,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: activeCount > 0
                                      ? primary
                                      : AppColors.muted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstCurve: Curves.easeOutCubic,
                secondCurve: Curves.easeInCubic,
                sizeCurve: Curves.easeOutCubic,
                crossFadeState: _filtersExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlaceTagFilterBar(
                      selected: widget.filterTags,
                      onChanged: widget.onFilterChanged,
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (widget.highlightBanner != null) widget.highlightBanner!,
              if (widget.locationHint != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: _LocationHintChip(message: widget.locationHint!),
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
