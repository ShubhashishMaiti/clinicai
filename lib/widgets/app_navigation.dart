import 'package:flutter/material.dart';

import '../core/app_export.dart';
import '../presentation/book_appointment_screen/book_appointment_screen.dart';

class _TabSpec {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final int? branchIndex;
  final bool isBookAction;

  const _TabSpec({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.branchIndex,
    this.isBookAction = false,
  });
}

const List<_TabSpec> _tabs = [
  _TabSpec(
    label: 'Dashboard',
    activeIcon: Icons.dashboard_rounded,
    inactiveIcon: Icons.dashboard_outlined,
    branchIndex: 0,
  ),
  _TabSpec(
    label: 'Appointments',
    activeIcon: Icons.event_note_rounded,
    inactiveIcon: Icons.event_note_outlined,
    branchIndex: 1,
  ),
  _TabSpec(
    label: 'Book',
    activeIcon: Icons.add_circle_rounded,
    inactiveIcon: Icons.add_circle_outline_rounded,
    isBookAction: true,
  ),
  _TabSpec(
    label: 'Patients',
    activeIcon: Icons.people_rounded,
    inactiveIcon: Icons.people_outline_rounded,
    branchIndex: 2,
  ),
  _TabSpec(
    label: 'Profile',
    activeIcon: Icons.person_rounded,
    inactiveIcon: Icons.person_outline_rounded,
    branchIndex: 3,
  ),
];

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedVisualIndex = 0;

  void _onTabTapped(int visualIndex) {
    final tab = _tabs[visualIndex];

    // Book action — open bottom sheet
    if (tab.isBookAction) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const BookAppointmentScreen(),
      );
      return;
    }

    if (tab.branchIndex == null) return;

    setState(() => _selectedVisualIndex = visualIndex);
    widget.navigationShell.goBranch(
      tab.branchIndex!,
      initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentBranch = widget.navigationShell.currentIndex;
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].branchIndex == currentBranch) {
        if (_selectedVisualIndex != i) {
          setState(() => _selectedVisualIndex = i);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationBar(
      selectedIndex: _selectedVisualIndex,
      onDestinationSelected: _onTabTapped,
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primaryContainer,
      elevation: 2,
      shadowColor: theme.colorScheme.outline,
      destinations: List.generate(_tabs.length, (i) {
        final tab = _tabs[i];
        final isBook = tab.isBookAction;
        return NavigationDestination(
          icon: isBook
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                )
              : Icon(
                  tab.inactiveIcon,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
          selectedIcon: isBook
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(100),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                )
              : Icon(
                  tab.activeIcon,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
          label: tab.label,
        );
      }),
    );
  }
}
