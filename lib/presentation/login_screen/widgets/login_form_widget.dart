import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../services/api_service.dart';

class LoginFormWidget extends StatefulWidget {
  const LoginFormWidget({super.key});

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _extractErrorMessage(DioException e) {
    // Connection / timeout errors
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Please check your internet connection.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. The server may be starting up — please try again in a moment.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server took too long to respond. Please try again.';
    }

    // HTTP error responses
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (statusCode == 401) {
      // Try to extract backend message
      if (responseData is Map) {
        final detail = responseData['detail'];
        if (detail is Map) {
          return detail['message']?.toString() ?? 'Invalid email or password.';
        } else if (detail is String) {
          return detail;
        }
      }
      return 'Invalid email or password. Please try again.';
    }

    if (statusCode == 422) {
      return 'Invalid request format. Please check your email and password.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'Server error ($statusCode). Please try again later.';
    }

    // Try to extract any detail message
    if (responseData is Map) {
      final detail = responseData['detail'];
      if (detail is Map) {
        return detail['message']?.toString() ??
            'Login failed. Please try again.';
      } else if (detail is String) {
        return detail;
      }
    }

    return 'Login failed (${statusCode ?? 'unknown error'}). Please try again.';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await ApiService().login(email, password);

      if (mounted) {
        setState(() => _isLoading = false);
        context.go(AppRoutes.dashboardScreen);
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      }
    } on TypeError {
      // Catches bad type casts in response parsing
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unexpected server response. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign In',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Access your clinic dashboard',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Email field
            Text(
              'Email Address',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'dr.smith@clinic.com',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CustomIconWidget(
                    iconName: 'email_outlined',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 48),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            Text(
              'Password',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CustomIconWidget(
                    iconName: 'lock_outline',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 48),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: CustomIconWidget(
                    iconName: _obscurePassword
                        ? 'visibility_off'
                        : 'visibility',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Remember me + Forgot password row
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? AppTheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: _rememberMe
                                ? AppTheme.primary
                                : theme.colorScheme.outline,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Sign In button
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(
                                (_glowAnim.value * 80).toInt(),
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primary.withAlpha(160),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
