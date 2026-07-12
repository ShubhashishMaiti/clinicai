import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class LoginHeaderWidget extends StatefulWidget {
  const LoginHeaderWidget({super.key});

  @override
  State<LoginHeaderWidget> createState() => _LoginHeaderWidgetState();
}

class _LoginHeaderWidgetState extends State<LoginHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          children: [
            // Logo mark
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.accent],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(89),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'medical_services',
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ClinicAI',
              style: GoogleFonts.sora(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your AI Receptionist, Always On',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.mutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
