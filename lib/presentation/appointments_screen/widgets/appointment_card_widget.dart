import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/status_badge_widget.dart';

class AppointmentModel {
  final String id;
  final String patientName;
  final String patientPhone;
  final String reason;
  final String date;
  final String time;
  final int duration;
  final String status;
  final bool isFirstVisit;
  final String initials;
  final String imageUrl;
  final String semanticLabel;
  final int gradientStart;
  final int gradientEnd;

  const AppointmentModel({
    required this.id,
    required this.patientName,
    required this.patientPhone,
    required this.reason,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    required this.isFirstVisit,
    required this.initials,
    required this.imageUrl,
    required this.semanticLabel,
    required this.gradientStart,
    required this.gradientEnd,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] as String,
      patientName: map['patientName'] as String,
      patientPhone: map['patientPhone'] as String,
      reason: map['reason'] as String,
      date: map['date'] as String,
      time: map['time'] as String,
      duration: map['duration'] as int,
      status: map['status'] as String,
      isFirstVisit: map['isFirstVisit'] as bool,
      initials: map['initials'] as String,
      imageUrl: map['imageUrl'] as String,
      semanticLabel: map['semanticLabel'] as String,
      gradientStart: map['gradientStart'] as int,
      gradientEnd: map['gradientEnd'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientName': patientName,
    'patientPhone': patientPhone,
    'reason': reason,
    'date': date,
    'time': time,
    'duration': duration,
    'status': status,
    'isFirstVisit': isFirstVisit,
    'initials': initials,
    'imageUrl': imageUrl,
    'semanticLabel': semanticLabel,
    'gradientStart': gradientStart,
    'gradientEnd': gradientEnd,
  };

  AppointmentModel copyWith({String? status}) => AppointmentModel(
    id: id,
    patientName: patientName,
    patientPhone: patientPhone,
    reason: reason,
    date: date,
    time: time,
    duration: duration,
    status: status ?? this.status,
    isFirstVisit: isFirstVisit,
    initials: initials,
    imageUrl: imageUrl,
    semanticLabel: semanticLabel,
    gradientStart: gradientStart,
    gradientEnd: gradientEnd,
  );

  AppointmentStatus get appointmentStatus {
    switch (status) {
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'rescheduled':
        return AppointmentStatus.rescheduled;
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      default:
        return AppointmentStatus.scheduled;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      case 'rescheduled':
        return AppTheme.warning;
      case 'pending':
        return const Color(0xFF7C3AED);
      default:
        return AppTheme.primary;
    }
  }
}

class AppointmentCardWidget extends StatefulWidget {
  final AppointmentModel appointment;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onTap;

  const AppointmentCardWidget({
    required this.appointment,
    required this.onComplete,
    required this.onCancel,
    required this.onReschedule,
    required this.onTap,
    super.key,
  });

  @override
  State<AppointmentCardWidget> createState() => _AppointmentCardWidgetState();
}

class _AppointmentCardWidgetState extends State<AppointmentCardWidget> {
  double _dragOffset = 0.0;
  bool _isDragging = false;
  static const double _threshold = 80.0;

  Color get _leftBgColor {
    // Revealed on right-swipe: Complete (green) + Reschedule (blue)
    if (_dragOffset > 0) {
      return _dragOffset > _threshold
          ? AppTheme.success.withAlpha(38)
          : AppTheme.success.withAlpha(20);
    }
    // Revealed on left-swipe: Cancel (red)
    if (_dragOffset < 0) {
      return (-_dragOffset) > _threshold
          ? AppTheme.error.withAlpha(38)
          : AppTheme.error.withAlpha(20);
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    final canSwipe = appt.status == 'scheduled' || appt.status == 'rescheduled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onHorizontalDragUpdate: canSwipe
            ? (details) {
                setState(() {
                  _dragOffset += details.delta.dx;
                  _dragOffset = _dragOffset.clamp(-160.0, 160.0);
                  _isDragging = true;
                });
              }
            : null,
        onHorizontalDragEnd: canSwipe
            ? (details) {
                if (_dragOffset > _threshold) {
                  widget.onComplete();
                } else if (_dragOffset < -_threshold) {
                  widget.onCancel();
                }
                setState(() {
                  _dragOffset = 0.0;
                  _isDragging = false;
                });
              }
            : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _leftBgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Background action hints
              if (_dragOffset > 20)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: AppTheme.success,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Done',
                            style: GoogleFonts.sora(
                              fontSize: 10,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'event_repeat',
                            color: AppTheme.primary,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reschedule',
                            style: GoogleFonts.sora(
                              fontSize: 10,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_dragOffset < -20)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'cancel_outlined',
                        color: AppTheme.error,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cancel',
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Card content
              Transform.translate(
                offset: Offset(_dragOffset * 0.4, 0),
                child: _buildCardContent(appt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(AppointmentModel appt) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: appt.statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with gradient rim
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(appt.gradientStart),
                        Color(appt.gradientEnd),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: CustomImageWidget(
                        imageUrl: appt.imageUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        semanticLabel: appt.semanticLabel,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appt.patientName,
                              style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceLight,
                              ),
                            ),
                          ),
                          StatusBadgeWidget(
                            status: appt.appointmentStatus,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        appt.reason,
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: AppTheme.mutedLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Divider
            Container(height: 1, color: AppTheme.outlineVariantLight),

            const SizedBox(height: 10),

            // Metadata row
            Row(
              children: [
                _MetaChip(iconName: 'schedule', label: appt.time),
                const SizedBox(width: 10),
                _MetaChip(
                  iconName: 'timer_outlined',
                  label: '${appt.duration} min',
                ),
                const SizedBox(width: 10),
                _MetaChip(
                  iconName: 'phone_outlined',
                  label:
                      '${appt.patientPhone.replaceAll('+1 ', '').substring(0, 8)}…',
                ),
                const Spacer(),
                if (appt.isFirstVisit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '1st Visit',
                      style: GoogleFonts.sora(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String iconName;
  final String label;

  const _MetaChip({required this.iconName, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.mutedLight,
          size: 13,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.mutedLight,
          ),
        ),
      ],
    );
  }
}
