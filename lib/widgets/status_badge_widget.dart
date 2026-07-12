import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum AppointmentStatus {
  scheduled,
  completed,
  cancelled,
  rescheduled,
  pending,
  confirmed,
}

class StatusBadgeWidget extends StatelessWidget {
  final AppointmentStatus status;
  final bool compact;

  const StatusBadgeWidget({
    required this.status,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config.label,
        style: GoogleFonts.sora(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: config.foreground,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.scheduled:
        return _StatusConfig(
          label: 'Scheduled',
          background: AppTheme.primaryContainer,
          foreground: AppTheme.primary,
        );
      case AppointmentStatus.completed:
        return _StatusConfig(
          label: 'Completed',
          background: AppTheme.successContainer,
          foreground: AppTheme.success,
        );
      case AppointmentStatus.cancelled:
        return _StatusConfig(
          label: 'Cancelled',
          background: AppTheme.errorContainer,
          foreground: AppTheme.error,
        );
      case AppointmentStatus.rescheduled:
        return _StatusConfig(
          label: 'Rescheduled',
          background: AppTheme.warningContainer,
          foreground: AppTheme.warning,
        );
      case AppointmentStatus.pending:
        return _StatusConfig(
          label: 'Pending',
          background: const Color(0xFFEDE9FE),
          foreground: const Color(0xFF7C3AED),
        );
      case AppointmentStatus.confirmed:
        return _StatusConfig(
          label: 'Confirmed',
          background: AppTheme.successContainer,
          foreground: AppTheme.success,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusConfig({
    required this.label,
    required this.background,
    required this.foreground,
  });
}
