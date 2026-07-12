import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import './widgets/demo_credentials_widget.dart';
import './widgets/login_form_widget.dart';
import './widgets/login_header_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFF), Color(0xFFEFF6FF), Color(0xFFF8FAFF)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 0 : 24,
                vertical: 32,
              ),
              child: isTablet
                  ? SizedBox(width: 480, child: _buildContent(context))
                  : _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LoginHeaderWidget(),
        const SizedBox(height: 32),
        const LoginFormWidget(),
        const SizedBox(height: 24),
        const DemoCredentialsWidget(),
        const SizedBox(height: 24),
        _buildLegalLinks(context),
      ],
    );
  }

  Widget _buildLegalLinks(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {},
          child: Text(
            'Privacy Policy',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '·',
          style: GoogleFonts.sora(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'Terms of Service',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
