import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class FeedFilterState {
  const FeedFilterState({
    this.status,
    this.symptoms = const {},
    this.bodyArea,
    this.hasPhotosOnly = false,
    this.journeysOnly = false,
    this.sortBy = '', // '' (auto), 'relevance', 'newest', 'top', 'journeys'
  });

  final String? status; // 'Asking' | 'Ongoing' | 'Healed'
  final Set<String> symptoms;
  final String? bodyArea;
  final bool hasPhotosOnly;
  final bool journeysOnly;
  final String sortBy;

  int get activeCount {
    int count = 0;
    if (status != null && status!.isNotEmpty) count++;
    count += symptoms.length;
    if (bodyArea != null && bodyArea!.isNotEmpty) count++;
    if (hasPhotosOnly) count++;
    if (journeysOnly) count++;
    if (sortBy.isNotEmpty) count++;
    return count;
  }

  bool get hasAny => activeCount > 0;

  FeedFilterState copyWith({
    String? status,
    bool clearStatus = false,
    Set<String>? symptoms,
    String? bodyArea,
    bool clearBodyArea = false,
    bool? hasPhotosOnly,
    bool? journeysOnly,
    String? sortBy,
  }) {
    return FeedFilterState(
      status: clearStatus ? null : (status ?? this.status),
      symptoms: symptoms ?? this.symptoms,
      bodyArea: clearBodyArea ? null : (bodyArea ?? this.bodyArea),
      hasPhotosOnly: hasPhotosOnly ?? this.hasPhotosOnly,
      journeysOnly: journeysOnly ?? this.journeysOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

const List<(String, String)> kSymptomOptions = [
  ('itchy', 'Itchy'),
  ('redness', 'Redness'),
  ('bumps', 'Bumps / Acne'),
  ('dry_flaky', 'Dry / Flaky'),
  ('blisters', 'Blisters'),
  ('ring_rash', 'Ring / Circular'),
  ('painful', 'Painful / Burning'),
  ('dark_spots', 'Dark Spots'),
  ('swelling', 'Swelling / Hives'),
  ('oozing', 'Oozing / Crust'),
];

const List<(String, String)> kBodyAreaOptions = [
  ('face', 'Face'),
  ('scalp', 'Scalp'),
  ('arms_hands', 'Arms & Hands'),
  ('legs_feet', 'Legs & Feet'),
  ('back_chest', 'Back & Chest'),
  ('neck', 'Neck'),
];

const List<(String, String)> kSortOptions = [
  ('relevance', 'Best Match'),
  ('top', 'Most Helpful'),
  ('newest', 'Newest'),
  ('journeys', 'Most Updates'),
];

/// Sleek single-row horizontal chip bar placed right below For You / Following
class QuickSymptomFilterBar extends StatelessWidget {
  const QuickSymptomFilterBar({
    required this.filters,
    required this.onFiltersChanged,
    required this.onOpenAllFilters,
    super.key,
  });

  final FeedFilterState filters;
  final ValueChanged<FeedFilterState> onFiltersChanged;
  final VoidCallback onOpenAllFilters;

  void _toggleSymptom(String key) {
    final next = Set<String>.from(filters.symptoms);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    onFiltersChanged(filters.copyWith(symptoms: next));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        children: [
          _quickChip(
            label: filters.hasAny
                ? 'Filters (${filters.activeCount})'
                : 'Filters',
            icon: Icons.tune_rounded,
            selected: filters.hasAny,
            onTap: onOpenAllFilters,
          ),
          const SizedBox(width: 8),
          _quickChip(
            label: 'Healed',
            icon: Icons.verified_outlined,
            selected: filters.status == 'Healed',
            onTap: () => onFiltersChanged(
              filters.status == 'Healed'
                  ? filters.copyWith(clearStatus: true)
                  : filters.copyWith(status: 'Healed'),
            ),
          ),
          const SizedBox(width: 8),
          _quickChip(
            label: 'With Photos',
            icon: Icons.photo_outlined,
            selected: filters.hasPhotosOnly,
            onTap: () => onFiltersChanged(
              filters.copyWith(hasPhotosOnly: !filters.hasPhotosOnly),
            ),
          ),
          const SizedBox(width: 8),
          _quickChip(
            label: 'Journeys',
            icon: Icons.timeline_rounded,
            selected: filters.journeysOnly,
            onTap: () => onFiltersChanged(
              filters.copyWith(journeysOnly: !filters.journeysOnly),
            ),
          ),
          const SizedBox(width: 8),
          ...kSymptomOptions.take(5).map((opt) {
            final (key, label) = opt;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _quickChip(
                label: label,
                selected: filters.symptoms.contains(key),
                onTap: () => _toggleSymptom(key),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _quickChip({
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full slide-up Symptom & Recovery Filter Bottom Sheet
Future<FeedFilterState?> showSymptomFilterSheet({
  required BuildContext context,
  required FeedFilterState initial,
}) {
  return showModalBottomSheet<FeedFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _SymptomFilterSheetBody(initial: initial),
  );
}

class _SymptomFilterSheetBody extends StatefulWidget {
  const _SymptomFilterSheetBody({required this.initial});

  final FeedFilterState initial;

  @override
  State<_SymptomFilterSheetBody> createState() =>
      _SymptomFilterSheetBodyState();
}

class _SymptomFilterSheetBodyState extends State<_SymptomFilterSheetBody> {
  late FeedFilterState _draft;

  @override
  void initState() {
    super.initState();
    _draft = FeedFilterState(
      status: widget.initial.status,
      symptoms: Set<String>.from(widget.initial.symptoms),
      bodyArea: widget.initial.bodyArea,
      hasPhotosOnly: widget.initial.hasPhotosOnly,
      journeysOnly: widget.initial.journeysOnly,
      sortBy: widget.initial.sortBy,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _selectableChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.22)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.manage_search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Filter by Symptoms',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _draft = const FeedFilterState());
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // 1. Recovery Status
                  _sectionTitle('Recovery Status'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _selectableChip(
                        label: 'All',
                        selected: _draft.status == null,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(clearStatus: true),
                        ),
                      ),
                      _selectableChip(
                        label: 'Healed',
                        selected: _draft.status == 'Healed',
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(status: 'Healed'),
                        ),
                      ),
                      _selectableChip(
                        label: 'Ongoing Treatment',
                        selected: _draft.status == 'Ongoing',
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(status: 'Ongoing'),
                        ),
                      ),
                      _selectableChip(
                        label: 'Just Asking',
                        selected: _draft.status == 'Asking',
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(status: 'Asking'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Symptoms (multi-select)
                  _sectionTitle('Symptoms (select all that match)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kSymptomOptions.map((opt) {
                      final (key, label) = opt;
                      final active = _draft.symptoms.contains(key);
                      return _selectableChip(
                        label: label,
                        selected: active,
                        onTap: () {
                          final next = Set<String>.from(_draft.symptoms);
                          if (active) {
                            next.remove(key);
                          } else {
                            next.add(key);
                          }
                          setState(
                            () => _draft = _draft.copyWith(symptoms: next),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Body Area
                  _sectionTitle('Body Area'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _selectableChip(
                        label: 'Any Area',
                        selected: _draft.bodyArea == null,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(clearBodyArea: true),
                        ),
                      ),
                      ...kBodyAreaOptions.map((opt) {
                        final (key, label) = opt;
                        return _selectableChip(
                          label: label,
                          selected: _draft.bodyArea == key,
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(bodyArea: key),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Visual & Journey toggles
                  _sectionTitle('Post Type'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _draft.hasPhotosOnly,
                          onChanged: (val) => setState(
                            () => _draft = _draft.copyWith(hasPhotosOnly: val),
                          ),
                          title: const Text(
                            'With Photos Only',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Show posts with visual photos for easier comparison',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          activeThumbColor: AppColors.primary,
                        ),
                        const Divider(color: AppColors.border, height: 1),
                        SwitchListTile(
                          value: _draft.journeysOnly,
                          onChanged: (val) => setState(
                            () => _draft = _draft.copyWith(journeysOnly: val),
                          ),
                          title: const Text(
                            'Recovery Journeys Only',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Only show multi-step timelines with follow-up updates',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 5. Sort Results
                  _sectionTitle('Sort Results By'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kSortOptions.map((opt) {
                      final (key, label) = opt;
                      final effective =
                          _draft.sortBy.isEmpty ? 'relevance' : _draft.sortBy;
                      return _selectableChip(
                        label: label,
                        selected: effective == key,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(sortBy: key),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Apply button bar
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_draft),
                    child: Text(
                      _draft.hasAny
                          ? 'Show Matching Posts (${_draft.activeCount} active)'
                          : 'Show All Posts',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}