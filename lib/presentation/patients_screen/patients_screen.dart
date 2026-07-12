import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_skeleton_widget.dart';
import './widgets/patient_card_widget.dart';
import './widgets/patient_detail_sheet.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _searchQuery = '';
  bool _sortByRecent = false;

  final List<Map<String, dynamic>> _allPatients = [
    {
      'id': 'p1',
      'name': 'Priya Sharma',
      'phone': '+1 (415) 555-0201',
      'age': 34,
      'gender': 'Female',
      'lastVisit': '2 days ago',
      'nextVisit': 'Tomorrow, 10:30 AM',
      'reason': 'Follow-up consultation',
      'visits': 5,
      'color': const Color(0xFF2563EB),
      'initials': 'PS',
    },
    {
      'id': 'p2',
      'name': 'James Okafor',
      'phone': '+1 (415) 555-0202',
      'age': 45,
      'gender': 'Male',
      'lastVisit': '1 week ago',
      'nextVisit': null,
      'reason': 'Annual checkup',
      'visits': 3,
      'color': const Color(0xFF10B981),
      'initials': 'JO',
    },
    {
      'id': 'p3',
      'name': 'Maria Gonzalez',
      'phone': '+1 (415) 555-0203',
      'age': 28,
      'gender': 'Female',
      'lastVisit': 'Today',
      'nextVisit': null,
      'reason': 'Skin rash evaluation',
      'visits': 2,
      'color': const Color(0xFFF59E0B),
      'initials': 'MG',
    },
    {
      'id': 'p4',
      'name': 'David Chen',
      'phone': '+1 (415) 555-0204',
      'age': 52,
      'gender': 'Male',
      'lastVisit': '3 days ago',
      'nextVisit': 'Next Monday, 2:00 PM',
      'reason': 'Blood pressure monitoring',
      'visits': 8,
      'color': const Color(0xFFEF4444),
      'initials': 'DC',
    },
    {
      'id': 'p5',
      'name': 'Aisha Patel',
      'phone': '+1 (415) 555-0205',
      'age': 31,
      'gender': 'Female',
      'lastVisit': '5 days ago',
      'nextVisit': null,
      'reason': 'Dental cleaning',
      'visits': 4,
      'color': const Color(0xFF8B5CF6),
      'initials': 'AP',
    },
    {
      'id': 'p6',
      'name': 'Robert Kim',
      'phone': '+1 (415) 555-0206',
      'age': 67,
      'gender': 'Male',
      'lastVisit': '2 weeks ago',
      'nextVisit': 'Friday, 11:00 AM',
      'reason': 'Diabetes management',
      'visits': 12,
      'color': const Color(0xFF0891B2),
      'initials': 'RK',
    },
    {
      'id': 'p7',
      'name': 'Sophie Williams',
      'phone': '+1 (415) 555-0207',
      'age': 22,
      'gender': 'Female',
      'lastVisit': 'Yesterday',
      'nextVisit': null,
      'reason': 'Acne treatment',
      'visits': 1,
      'color': const Color(0xFFEC4899),
      'initials': 'SW',
    },
    {
      'id': 'p8',
      'name': 'Michael Torres',
      'phone': '+1 (415) 555-0208',
      'age': 39,
      'gender': 'Male',
      'lastVisit': '10 days ago',
      'nextVisit': 'Thursday, 3:30 PM',
      'reason': 'Back pain consultation',
      'visits': 6,
      'color': const Color(0xFF059669),
      'initials': 'MT',
    },
  ];

  List<Map<String, dynamic>> get _filteredPatients {
    List<Map<String, dynamic>> list = _allPatients;
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        final name = (p['name'] as String).toLowerCase();
        final phone = (p['phone'] as String).toLowerCase();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || phone.contains(q);
      }).toList();
    }
    if (_sortByRecent) {
      list = List.from(list.reversed);
    } else {
      list = List.from(list)
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPatientDetail(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PatientDetailSheet(patient: patient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredPatients;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppTheme.surfaceLight,
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Patients',
                        style: GoogleFonts.sora(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurfaceLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_allPatients.length} total',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      color: AppTheme.onSurfaceLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search patients by name or phone…',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.mutedLight,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(
                                Icons.close,
                                color: AppTheme.mutedLight,
                                size: 18,
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  // Sort toggle
                  Row(
                    children: [
                      Text(
                        'Sort by:',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _sortByRecent = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: !_sortByRecent
                                ? AppTheme.primary
                                : AppTheme.surfaceVariantLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'A–Z',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: !_sortByRecent
                                  ? Colors.white
                                  : AppTheme.mutedLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _sortByRecent = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _sortByRecent
                                ? AppTheme.primary
                                : AppTheme.surfaceVariantLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Recent',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _sortByRecent
                                  ? Colors.white
                                  : AppTheme.mutedLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: _isLoading
                  ? _buildSkeletons()
                  : filtered.isEmpty
                  ? EmptyStateWidget(
                      iconName: 'people_outline',
                      title: _searchQuery.isNotEmpty
                          ? 'No results found'
                          : 'No patients yet',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'Try a different name or phone number'
                          : 'Your Vapi receptionist will add patients automatically when they call.',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final patient = filtered[index];
                        return PatientCardWidget(
                          patient: patient,
                          onTap: () => _openPatientDetail(patient),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const LoadingSkeletonWidget(
        width: double.infinity,
        height: 88,
        borderRadius: 20,
      ),
    );
  }
}