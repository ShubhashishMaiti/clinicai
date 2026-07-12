import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import './widgets/kpi_grid_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/recent_patients_widget.dart';
import './widgets/section_header_widget.dart';
import './widgets/timeline_rail_widget.dart';
import './widgets/weekly_chart_widget.dart';

// TODO: Replace with [Riverpod/Bloc] for production data fetching

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _staggerController;

  // TODO: Replace with [Riverpod/Bloc] state — fetch from /api/dashboard/summary
  final Map<String, int> _kpiData = {
    'today': 8,
    'upcoming': 23,
    'completed': 5,
    'pending': 3,
  };

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    // TODO: Replace with [Riverpod/Bloc] real API call to /api/dashboard/summary
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isLoading = false);
      _staggerController.forward();
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = false);
    _staggerController.reset();
    await _loadDashboard();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime(2026, 7, 12, 13, 8);

    String greeting;
    final hour = now.hour;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Custom AppBar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppTheme.backgroundLight,
                elevation: 0,
                scrolledUnderElevation: 1,
                shadowColor: AppTheme.outlineLight,
                expandedHeight: 72,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildAppBar(context, greeting),
                ),
              ),

              SliverToBoxAdapter(
                child: _isLoading ? _buildSkeletonBody() : _buildBody(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String greeting) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$greeting, Dr. Smith',
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  'Bloom Family Clinic · Sat, Jul 12',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'notifications_outlined',
                    color: AppTheme.onSurfaceLight,
                    size: 22,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'SS',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // KPI Grid
          _StaggerItem(
            controller: _staggerController,
            index: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KpiGridWidget(kpiData: _kpiData),
            ),
          ),

          const SizedBox(height: 24),

          // Weekly chart
          _StaggerItem(
            controller: _staggerController,
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const WeeklyChartWidget(),
            ),
          ),

          const SizedBox(height: 24),

          // Today's Timeline
          _StaggerItem(
            controller: _staggerController,
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeaderWidget(
                    title: "Today's Timeline",
                    actionLabel: 'View all',
                    onAction: () {},
                  ),
                ),
                const SizedBox(height: 12),
                const TimelineRailWidget(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent Patients
          _StaggerItem(
            controller: _staggerController,
            index: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeaderWidget(
                    title: 'Recent Patients',
                    actionLabel: 'See all',
                    onAction: () {},
                  ),
                ),
                const SizedBox(height: 12),
                const RecentPatientsWidget(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          _StaggerItem(
            controller: _staggerController,
            index: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeaderWidget(
                    title: 'Quick Actions',
                    actionLabel: null,
                    onAction: null,
                  ),
                  const SizedBox(height: 12),
                  const QuickActionsWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // KPI skeleton
          Row(
            children: List.generate(
              2,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              2,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggerItem extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggerItem({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.12).clamp(0.0, 0.8);
    final end = (start + 0.4).clamp(0.0, 1.0);

    final slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );

    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(position: slideAnim, child: child),
      ),
    );
  }
}
