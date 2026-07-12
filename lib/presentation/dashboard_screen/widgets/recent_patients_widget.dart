import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

// TODO: Replace with [Riverpod/Bloc] — fetch from /api/patients with recent filter

class _RecentPatient {
  final String name;
  final String initials;
  final String lastVisit;
  final String reason;
  final List<Color> avatarGradient;
  final String imageUrl;
  final String semanticLabel;

  const _RecentPatient({
    required this.name,
    required this.initials,
    required this.lastVisit,
    required this.reason,
    required this.avatarGradient,
    required this.imageUrl,
    required this.semanticLabel,
  });
}

class RecentPatientsWidget extends StatelessWidget {
  const RecentPatientsWidget({super.key});

  static final List<_RecentPatient> _patients = [
    _RecentPatient(
      name: 'Marcus Rivera',
      initials: 'MR',
      lastVisit: 'Today, 9:00 AM',
      reason: 'Annual checkup',
      avatarGradient: [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
      imageUrl:
          'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=80',
      semanticLabel: 'Hispanic man with short dark hair, professional headshot',
    ),
    _RecentPatient(
      name: 'Priya Nair',
      initials: 'PN',
      lastVisit: 'Today, 9:30 AM',
      reason: 'BP review',
      avatarGradient: [const Color(0xFF7C3AED), const Color(0xFFEC4899)],
      imageUrl:
          'https://images.pixabay.com/photo/2016/11/29/13/14/attractive-1870960_640.jpg',
      semanticLabel:
          'South Asian woman with dark hair, smiling, professional photo',
    ),
    _RecentPatient(
      name: 'James Okonkwo',
      initials: 'JO',
      lastVisit: 'Today, 10:00 AM',
      reason: 'Flu symptoms',
      avatarGradient: [const Color(0xFF10B981), const Color(0xFF059669)],
      imageUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80',
      semanticLabel:
          'Black man with short hair, friendly expression, casual attire',
    ),
    _RecentPatient(
      name: 'Sofia Hernandez',
      initials: 'SH',
      lastVisit: 'Today, 10:30 AM',
      reason: 'Diabetes follow-up',
      avatarGradient: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      imageUrl:
          'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=80',
      semanticLabel:
          'Latina woman with curly hair, warm smile, close-up portrait',
    ),
    _RecentPatient(
      name: 'Amara Osei',
      initials: 'AO',
      lastVisit: 'Now · 1:30 PM',
      reason: 'Skin rash',
      avatarGradient: [const Color(0xFF2563EB), const Color(0xFF7C3AED)],
      imageUrl:
          'https://images.pixabay.com/photo/2017/08/01/08/29/woman-2563491_640.jpg',
      semanticLabel: 'African woman with natural hair, professional portrait',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _patients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = _patients[i];
          return _PatientHorizontalCard(patient: p);
        },
      ),
    );
  }
}

class _PatientHorizontalCard extends StatelessWidget {
  final _RecentPatient patient;

  const _PatientHorizontalCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gradient rim avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: patient.avatarGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: CustomImageWidget(
                  imageUrl: patient.imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  semanticLabel: patient.semanticLabel,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            patient.name.split(' ').first,
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            patient.reason,
            style: GoogleFonts.sora(fontSize: 10, color: AppTheme.mutedLight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
