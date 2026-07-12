import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class FilterChipRowWidget extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const FilterChipRowWidget({
    required this.selectedFilter,
    required this.onFilterSelected,
    super.key,
  });

  static const List<String> _filters = [
    'Today',
    'Tomorrow',
    'Upcoming',
    'Completed',
    'Cancelled',
    'Rescheduled',
    'All',
  ];

  Color _chipColor(String filter) {
    switch (filter) {
      case 'Completed':
        return AppTheme.success;
      case 'Cancelled':
        return AppTheme.error;
      case 'Rescheduled':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          final isSelected = selectedFilter == filter;
          final chipColor = _chipColor(filter);

          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? chipColor : AppTheme.outlineLight,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: chipColor.withAlpha(64),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppTheme.mutedLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
