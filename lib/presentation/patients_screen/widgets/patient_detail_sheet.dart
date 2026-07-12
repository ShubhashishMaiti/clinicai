import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';
import '../../book_appointment_screen/book_appointment_screen.dart';

class PatientDetailSheet extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientDetailSheet({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final Color avatarColor = patient['color'] as Color;
    final String initials = patient['initials'] as String;

    return Container(
      height: 85.h,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Grabber
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const Spacer(),
                Text(
                  'Patient Details',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppTheme.mutedLight,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  SizedBox(height: 1.h),
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [avatarColor, avatarColor.withAlpha(180)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: avatarColor.withAlpha(100),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.sora(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Text(
                    patient['name'] as String,
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${patient['age']} years • ${patient['gender']}',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Action row
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.phone_outlined,
                          label: 'Call',
                          color: AppTheme.primary,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.calendar_today_outlined,
                          label: 'Book',
                          color: AppTheme.primary,
                          filled: true,
                          onTap: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BookAppointmentScreen(
                                prefilledPatient: patient,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  // AI Summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withAlpha(15),
                          AppTheme.accent.withAlpha(8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withAlpha(40)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI Summary',
                              style: GoogleFonts.sora(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.refresh,
                              size: 16,
                              color: AppTheme.mutedLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${patient['name']} is a ${patient['age']}-year-old ${(patient['gender'] as String).toLowerCase()} with ${patient['visits']} recorded visits. Most recent concern: ${patient['reason']}. Patient shows consistent follow-up behavior and responds well to treatment plans.',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            color: AppTheme.onSurfaceLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Info rows
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: patient['phone'] as String,
                  ),
                  const Divider(height: 1, color: AppTheme.outlineVariantLight),
                  _InfoRow(
                    icon: Icons.history,
                    label: 'Last Visit',
                    value: patient['lastVisit'] as String,
                  ),
                  if (patient['nextVisit'] != null) ...[
                    const Divider(
                      height: 1,
                      color: AppTheme.outlineVariantLight,
                    ),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: 'Next Visit',
                      value: patient['nextVisit'] as String,
                      valueColor: AppTheme.primary,
                    ),
                  ],
                  const Divider(height: 1, color: AppTheme.outlineVariantLight),
                  _InfoRow(
                    icon: Icons.medical_services_outlined,
                    label: 'Reason',
                    value: patient['reason'] as String,
                  ),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: filled ? Colors.white : color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.mutedLight),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.sora(fontSize: 13, color: AppTheme.mutedLight),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.onSurfaceLight,
            ),
          ),
        ],
      ),
    );
  }
}
