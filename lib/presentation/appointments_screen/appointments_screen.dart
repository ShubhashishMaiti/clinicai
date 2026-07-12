import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_skeleton_widget.dart';
import '../book_appointment_screen/book_appointment_screen.dart';
import './widgets/appointment_card_widget.dart';
import './widgets/appointments_search_widget.dart';
import './widgets/filter_chip_row_widget.dart';

// TODO: Replace with [Riverpod/Bloc] for production data fetching from /api/appointments

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Today';
  String _searchQuery = '';
  bool _isLoading = true;
  late AnimationController _staggerController;

  // TODO: Replace with [Riverpod/Bloc] — fetch from /api/appointments?filter=...
  static final List<Map<String, dynamic>> _appointmentMaps = [
    {
      'id': 'appt-001',
      'patientName': 'Amara Osei',
      'patientPhone': '+1 (415) 555-0201',
      'reason': 'Skin rash consultation',
      'date': '2026-07-12',
      'time': '1:30 PM',
      'duration': 30,
      'status': 'scheduled',
      'isFirstVisit': false,
      'initials': 'AO',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1a5b689fb-1763296744210.png',
      'semanticLabel': 'African woman with natural hair, professional portrait',
      'gradientStart': 0xFF2563EB,
      'gradientEnd': 0xFF7C3AED,
    },
    {
      'id': 'appt-002',
      'patientName': 'Lena Fischer',
      'patientPhone': '+1 (415) 555-0202',
      'reason': 'Post-surgery follow-up',
      'date': '2026-07-12',
      'time': '2:00 PM',
      'duration': 30,
      'status': 'scheduled',
      'isFirstVisit': false,
      'initials': 'LF',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_16e75c406-1763294340369.png',
      'semanticLabel': 'Caucasian woman with blonde hair, professional photo',
      'gradientStart': 0xFF7C3AED,
      'gradientEnd': 0xFFEC4899,
    },
    {
      'id': 'appt-003',
      'patientName': 'Raj Sharma',
      'patientPhone': '+1 (415) 555-0203',
      'reason': 'New patient intake',
      'date': '2026-07-12',
      'time': '2:30 PM',
      'duration': 45,
      'status': 'scheduled',
      'isFirstVisit': true,
      'initials': 'RS',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1dfb195e0-1763297684607.png',
      'semanticLabel': 'South Asian man with dark hair, smiling headshot',
      'gradientStart': 0xFF10B981,
      'gradientEnd': 0xFF059669,
    },
    {
      'id': 'appt-004',
      'patientName': 'Chen Wei',
      'patientPhone': '+1 (415) 555-0204',
      'reason': 'Prescription renewal',
      'date': '2026-07-12',
      'time': '3:00 PM',
      'duration': 20,
      'status': 'scheduled',
      'isFirstVisit': false,
      'initials': 'CW',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1b1db1739-1763296537435.png',
      'semanticLabel': 'East Asian man with glasses, professional portrait',
      'gradientStart': 0xFF2563EB,
      'gradientEnd': 0xFF06B6D4,
    },
    {
      'id': 'appt-005',
      'patientName': 'Fatima Al-Hassan',
      'patientPhone': '+1 (415) 555-0205',
      'reason': 'Lab results review',
      'date': '2026-07-12',
      'time': '3:30 PM',
      'duration': 30,
      'status': 'rescheduled',
      'isFirstVisit': false,
      'initials': 'FA',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1eec778e9-1766069487817.png',
      'semanticLabel': 'Middle Eastern woman with hijab, professional portrait',
      'gradientStart': 0xFFF59E0B,
      'gradientEnd': 0xFFEF4444,
    },
    {
      'id': 'appt-006',
      'patientName': 'Marcus Rivera',
      'patientPhone': '+1 (415) 555-0101',
      'reason': 'Annual checkup',
      'date': '2026-07-12',
      'time': '9:00 AM',
      'duration': 30,
      'status': 'completed',
      'isFirstVisit': false,
      'initials': 'MR',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_138df7967-1763295321074.png',
      'semanticLabel':
          'Hispanic man with short dark hair, professional headshot',
      'gradientStart': 0xFF2563EB,
      'gradientEnd': 0xFF06B6D4,
    },
    {
      'id': 'appt-007',
      'patientName': 'Priya Nair',
      'patientPhone': '+1 (415) 555-0102',
      'reason': 'Blood pressure review',
      'date': '2026-07-12',
      'time': '9:30 AM',
      'duration': 20,
      'status': 'completed',
      'isFirstVisit': false,
      'initials': 'PN',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_17133b899-1763292391287.png',
      'semanticLabel':
          'South Asian woman with dark hair, smiling professional photo',
      'gradientStart': 0xFF7C3AED,
      'gradientEnd': 0xFFEC4899,
    },
    {
      'id': 'appt-008',
      'patientName': 'David Park',
      'patientPhone': '+1 (415) 555-0106',
      'reason': 'Chest X-ray review',
      'date': '2026-07-12',
      'time': '11:00 AM',
      'duration': 30,
      'status': 'completed',
      'isFirstVisit': false,
      'initials': 'DP',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_17793ff59-1763292808916.png',
      'semanticLabel': 'Korean man with short hair, professional headshot',
      'gradientStart': 0xFF10B981,
      'gradientEnd': 0xFF059669,
    },
    {
      'id': 'appt-009',
      'patientName': 'Isabella Costa',
      'patientPhone': '+1 (415) 555-0301',
      'reason': 'Migraine consultation',
      'date': '2026-07-13',
      'time': '10:00 AM',
      'duration': 30,
      'status': 'scheduled',
      'isFirstVisit': true,
      'initials': 'IC',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1661da008-1763296604528.png',
      'semanticLabel':
          'Brazilian woman with dark wavy hair, professional portrait',
      'gradientStart': 0xFF2563EB,
      'gradientEnd': 0xFF06B6D4,
    },
    {
      'id': 'appt-010',
      'patientName': 'Kwame Asante',
      'patientPhone': '+1 (415) 555-0302',
      'reason': 'Hypertension management',
      'date': '2026-07-13',
      'time': '11:00 AM',
      'duration': 30,
      'status': 'scheduled',
      'isFirstVisit': false,
      'initials': 'KA',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1fdcca27f-1763292183642.png',
      'semanticLabel':
          'Ghanaian man with short hair, confident expression, professional photo',
      'gradientStart': 0xFF7C3AED,
      'gradientEnd': 0xFFEC4899,
    },
    {
      'id': 'appt-011',
      'patientName': 'Yuki Tanaka',
      'patientPhone': '+1 (415) 555-0303',
      'reason': 'Allergy testing follow-up',
      'date': '2026-07-14',
      'time': '9:30 AM',
      'duration': 45,
      'status': 'scheduled',
      'isFirstVisit': false,
      'initials': 'YT',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1c2c344ce-1763299429241.png',
      'semanticLabel':
          'Japanese woman with straight black hair, professional headshot',
      'gradientStart': 0xFF10B981,
      'gradientEnd': 0xFF059669,
    },
    {
      'id': 'appt-012',
      'patientName': 'Omar Khalil',
      'patientPhone': '+1 (415) 555-0304',
      'reason': 'Thyroid panel review',
      'date': '2026-07-11',
      'time': '2:00 PM',
      'duration': 30,
      'status': 'cancelled',
      'isFirstVisit': false,
      'initials': 'OK',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_13dfae0f7-1763294120490.png',
      'semanticLabel': 'Middle Eastern man with beard, professional portrait',
      'gradientStart': 0xFFEF4444,
      'gradientEnd': 0xFFF59E0B,
    },
  ];

  late List<AppointmentModel> _allAppointments;
  late List<AppointmentModel> _filteredAppointments;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _allAppointments = _appointmentMaps.map(AppointmentModel.fromMap).toList();
    _filteredAppointments = List.from(_allAppointments);
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    // TODO: Replace with [Riverpod/Bloc] real API call to /api/appointments
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
      _applyFilter(_selectedFilter);
      _staggerController.forward();
    }
  }

  Future<void> _onRefresh() async {
    _staggerController.reset();
    setState(() => _isLoading = true);
    await _loadAppointments();
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _staggerController.reset();
      final now = DateTime(2026, 7, 12);
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      List<AppointmentModel> result = List.from(_allAppointments);

      // Apply search
      if (_searchQuery.isNotEmpty) {
        result = result
            .where(
              (a) =>
                  a.patientName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  a.reason.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
      }

      switch (filter) {
        case 'Today':
          result = result.where((a) {
            final d = DateTime.parse(a.date);
            return d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
          }).toList();
          break;
        case 'Tomorrow':
          result = result.where((a) {
            final d = DateTime.parse(a.date);
            return d.year == tomorrow.year &&
                d.month == tomorrow.month &&
                d.day == tomorrow.day;
          }).toList();
          break;
        case 'Upcoming':
          result = result
              .where(
                (a) =>
                    DateTime.parse(a.date).isAfter(today) &&
                    a.status == 'scheduled',
              )
              .toList();
          break;
        case 'Completed':
          result = result.where((a) => a.status == 'completed').toList();
          break;
        case 'Cancelled':
          result = result.where((a) => a.status == 'cancelled').toList();
          break;
        case 'Rescheduled':
          result = result.where((a) => a.status == 'rescheduled').toList();
          break;
        case 'All':
        default:
          break;
      }

      _filteredAppointments = result;
      _staggerController.forward();
    });
  }

  void _onSearchChanged(String q) {
    setState(() => _searchQuery = q);
    _applyFilter(_selectedFilter);
  }

  void _onSwipeComplete(String id) {
    // TODO: Replace with [Riverpod/Bloc] — PATCH /api/appointments/{id}/complete
    setState(() {
      final idx = _allAppointments.indexWhere((a) => a.id == id);
      if (idx >= 0) {
        _allAppointments[idx] = _allAppointments[idx].copyWith(
          status: 'completed',
        );
      }
      _applyFilter(_selectedFilter);
    });
  }

  void _onSwipeCancel(String id) {
    // TODO: Replace with [Riverpod/Bloc] — POST /api/appointments/{id}/cancel
    setState(() {
      final idx = _allAppointments.indexWhere((a) => a.id == id);
      if (idx >= 0) {
        _allAppointments[idx] = _allAppointments[idx].copyWith(
          status: 'cancelled',
        );
      }
      _applyFilter(_selectedFilter);
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed chrome: AppBar
            _buildAppBar(context),

            // Fixed chrome: Search bar
            AppointmentsSearchWidget(onChanged: _onSearchChanged),

            const SizedBox(height: 8),

            // Fixed chrome: Filter chips
            FilterChipRowWidget(
              selectedFilter: _selectedFilter,
              onFilterSelected: _applyFilter,
            ),

            const SizedBox(height: 8),

            // Scrollable body
            Expanded(
              child: _isLoading
                  ? _buildSkeletonList()
                  : _filteredAppointments.isEmpty
                  ? EmptyStateWidget(
                      iconName: 'event_busy',
                      title: 'No appointments found',
                      subtitle:
                          'No appointments match the "$_selectedFilter" filter. Try a different filter or pull down to refresh.',
                      ctaLabel: 'Book Appointment',
                      onCta: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const BookAppointmentScreen(),
                        );
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 24,
                          top: 4,
                        ),
                        itemCount: _filteredAppointments.length,
                        itemBuilder: (context, i) {
                          final appt = _filteredAppointments[i];
                          return _StaggerListItem(
                            controller: _staggerController,
                            index: i,
                            child: AppointmentCardWidget(
                              appointment: appt,
                              onComplete: () => _onSwipeComplete(appt.id),
                              onCancel: () => _onSwipeCancel(appt.id),
                              onReschedule: () {},
                              onTap: () {},
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const BookAppointmentScreen(),
          );
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: CustomIconWidget(
          iconName: 'add_rounded',
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'Book Appointment',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointments',
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  'Saturday, Jul 12, 2026',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'event_note',
                  color: AppTheme.primary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_filteredAppointments.length} shown',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonAppointmentCard(),
    );
  }
}

class _StaggerListItem extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggerListItem({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final delay = (index * 0.07).clamp(0.0, 0.7);
    final end = (delay + 0.35).clamp(0.0, 1.0);

    final slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(delay, end, curve: Curves.easeOutCubic),
          ),
        );

    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay, end, curve: Curves.easeOut),
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
