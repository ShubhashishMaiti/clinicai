import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/status_badge_widget.dart';

// TODO: Replace with [Riverpod/Bloc] — fetch from /api/calendar?view=day

class _TimelineSlot {
  final String time;
  final String? patientName;
  final String? reason;
  final AppointmentStatus? status;
  final bool isNow;
  final bool isBreak;

  const _TimelineSlot({
    required this.time,
    this.patientName,
    this.reason,
    this.status,
    this.isNow = false,
    this.isBreak = false,
  });
}

class TimelineRailWidget extends StatefulWidget {
  const TimelineRailWidget({super.key});

  @override
  State<TimelineRailWidget> createState() => _TimelineRailWidgetState();
}

class _TimelineRailWidgetState extends State<TimelineRailWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const List<_TimelineSlot> _slots = [
    _TimelineSlot(
      time: '9:00 AM',
      patientName: 'Marcus Rivera',
      reason: 'Annual checkup',
      status: AppointmentStatus.completed,
    ),
    _TimelineSlot(
      time: '9:30 AM',
      patientName: 'Priya Nair',
      reason: 'Blood pressure review',
      status: AppointmentStatus.completed,
    ),
    _TimelineSlot(
      time: '10:00 AM',
      patientName: 'James Okonkwo',
      reason: 'Flu symptoms',
      status: AppointmentStatus.completed,
    ),
    _TimelineSlot(
      time: '10:30 AM',
      patientName: 'Sofia Hernandez',
      reason: 'Diabetes follow-up',
      status: AppointmentStatus.completed,
    ),
    _TimelineSlot(
      time: '11:00 AM',
      patientName: 'David Park',
      reason: 'Chest X-ray review',
      status: AppointmentStatus.completed,
    ),
    _TimelineSlot(time: '12:00 PM', isBreak: true),
    _TimelineSlot(time: '1:00 PM', isBreak: true),
    _TimelineSlot(
      time: '1:30 PM',
      patientName: 'Amara Osei',
      reason: 'Skin rash consultation',
      status: AppointmentStatus.scheduled,
      isNow: true,
    ),
    _TimelineSlot(
      time: '2:00 PM',
      patientName: 'Lena Fischer',
      reason: 'Post-surgery follow-up',
      status: AppointmentStatus.scheduled,
    ),
    _TimelineSlot(
      time: '2:30 PM',
      patientName: 'Raj Sharma',
      reason: 'New patient intake',
      status: AppointmentStatus.scheduled,
    ),
    _TimelineSlot(
      time: '3:00 PM',
      patientName: 'Chen Wei',
      reason: 'Prescription renewal',
      status: AppointmentStatus.scheduled,
    ),
    _TimelineSlot(
      time: '3:30 PM',
      patientName: 'Fatima Al-Hassan',
      reason: 'Lab results review',
      status: AppointmentStatus.rescheduled,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _slots.length > 6 ? 6 : _slots.length,
        itemBuilder: (context, i) {
          return _buildSlotItem(_slots[i], i, i == _slots.length - 1);
        },
      ),
    );
  }

  Widget _buildSlotItem(_TimelineSlot slot, int index, bool isLast) {
    if (slot.isBreak) {
      return _buildBreakSlot(slot);
    }

    Color leftColor = AppTheme.outlineLight;
    if (slot.status == AppointmentStatus.completed) {
      leftColor = AppTheme.success;
    } else if (slot.status == AppointmentStatus.scheduled) {
      leftColor = AppTheme.primary;
    } else if (slot.status == AppointmentStatus.rescheduled) {
      leftColor = AppTheme.warning;
    } else if (slot.status == AppointmentStatus.cancelled) {
      leftColor = AppTheme.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                slot.time,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: slot.isNow ? AppTheme.primary : AppTheme.mutedLight,
                ),
              ),
            ),
          ),

          // Timeline line + dot
          Column(
            children: [
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  if (slot.isNow)
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, _) => Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withOpacity(
                            _pulseAnim.value * 0.3,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: leftColor,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 48,
                  color: AppTheme.outlineVariantLight,
                ),
            ],
          ),

          const SizedBox(width: 10),

          // Card content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: slot.isNow
                    ? AppTheme.accentLight
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: slot.isNow
                    ? Border.all(
                        color: AppTheme.primary.withAlpha(77),
                        width: 1,
                      )
                    : Border.all(color: AppTheme.outlineVariantLight, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.patientName ?? '',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          slot.reason ?? '',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (slot.status != null)
                    StatusBadgeWidget(status: slot.status!, compact: true),
                  if (slot.isNow) ...[
                    const SizedBox(width: 6),
                    CustomIconWidget(
                      iconName: 'arrow_forward_ios',
                      color: AppTheme.primary,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakSlot(_TimelineSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              slot.time,
              style: GoogleFonts.sora(fontSize: 11, color: AppTheme.mutedLight),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outlineLight, width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Lunch Break',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
