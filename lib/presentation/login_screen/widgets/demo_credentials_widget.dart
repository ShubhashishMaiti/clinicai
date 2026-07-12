import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';

class _DemoAccount {
  final String role;
  final String email;
  final String password;

  const _DemoAccount({
    required this.role,
    required this.email,
    required this.password,
  });
}

class DemoCredentialsWidget extends StatelessWidget {
  const DemoCredentialsWidget({super.key});

  static const List<_DemoAccount> _accounts = [
    _DemoAccount(
      role: 'Admin',
      email: 'admin@clinic.com',
      password: 'Admin@123',
    ),
    _DemoAccount(
      role: 'Dr. Smith',
      email: 'dr.smith@clinic.com',
      password: 'Demo@123',
    ),
    _DemoAccount(
      role: 'Dr. Patel',
      email: 'dr.patel@clinic.com',
      password: 'Demo@123',
    ),
    _DemoAccount(
      role: 'Dr. Chen',
      email: 'dr.chen@clinic.com',
      password: 'Demo@123',
    ),
  ];

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: GoogleFonts.sora(fontSize: 13, color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryContainer, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info_outline',
                color: AppTheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Demo Accounts',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_accounts.length, (i) {
            final acc = _accounts[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < _accounts.length - 1 ? 8 : 0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        acc.role,
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.email,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            acc.password,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copyToClipboard(context, acc.email),
                      child: CustomIconWidget(
                        iconName: 'content_copy',
                        color: AppTheme.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
