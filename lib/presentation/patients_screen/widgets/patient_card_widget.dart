import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class PatientCardWidget extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;

  const PatientCardWidget({
    super.key,
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color avatarColor = patient['color'] as Color;
    final String initials = patient['initials'] as String;
    final String? nextVisit = patient['nextVisit'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outlineVariantLight),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: const Color(0xFF2563EB).withAlpha(8),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [avatarColor, avatarColor.withAlpha(180)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: avatarColor.withAlpha(80), width: 2),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          patient['name'] as String,
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${patient['visits']} visits',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient['phone'] as String,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${patient['age']} • ${patient['gender']}',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppTheme.mutedLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nextVisit != null
                              ? 'Next: $nextVisit'
                              : 'Last: ${patient['lastVisit']}',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: nextVisit != null
                                ? AppTheme.primary
                                : AppTheme.mutedLight,
                            fontWeight: nextVisit != null
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.mutedLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
