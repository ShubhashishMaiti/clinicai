import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _vacationMode = false;
  bool _darkMode = false;
  bool _smsNotifications = true;
  bool _pushNotifications = true;

  final Map<String, dynamic> _doctor = {
    'name': 'Dr. Sarah Smith',
    'specialization': 'General Physician',
    'email': 'dr.smith@clinic.com',
    'phone': '+1 (415) 555-0101',
    'clinicName': 'Bloom Family Clinic',
    'clinicAddress': '123 Wellness Ave, San Francisco, CA',
    'inboundPhone': '+14155550101',
    'workingHours': '9:00 AM – 5:00 PM',
    'workingDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    'breakTime': '1:00 PM – 2:00 PM',
    'initials': 'SS',
    'isAdmin': false,
  };

  final List<String> _allDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  void _openEditProfile() {
    final nameCtrl = TextEditingController(text: _doctor['name'] as String);
    final specCtrl = TextEditingController(
      text: _doctor['specialization'] as String,
    );
    final clinicCtrl = TextEditingController(
      text: _doctor['clinicName'] as String,
    );
    final phoneCtrl = TextEditingController(text: _doctor['phone'] as String);
    final hoursCtrl = TextEditingController(
      text: _doctor['workingHours'] as String,
    );
    final breakCtrl = TextEditingController(
      text: _doctor['breakTime'] as String,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                // Title row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurfaceLight,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(
                          Icons.close,
                          size: 22,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.outlineVariantLight),
                // Fields
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _EditField(
                          label: 'Full Name',
                          controller: nameCtrl,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        _EditField(
                          label: 'Specialization',
                          controller: specCtrl,
                          icon: Icons.medical_services_outlined,
                        ),
                        const SizedBox(height: 14),
                        _EditField(
                          label: 'Clinic Name',
                          controller: clinicCtrl,
                          icon: Icons.local_hospital_outlined,
                        ),
                        const SizedBox(height: 14),
                        _EditField(
                          label: 'Phone',
                          controller: phoneCtrl,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _EditField(
                          label: 'Working Hours',
                          controller: hoursCtrl,
                          icon: Icons.access_time_outlined,
                          hint: 'e.g. 9:00 AM – 5:00 PM',
                        ),
                        const SizedBox(height: 14),
                        _EditField(
                          label: 'Break Time',
                          controller: breakCtrl,
                          icon: Icons.free_breakfast_outlined,
                          hint: 'e.g. 1:00 PM – 2:00 PM',
                        ),
                        const SizedBox(height: 24),
                        // Save button
                        StatefulBuilder(
                          builder: (context, setSaveState) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _doctor['name'] = nameCtrl.text.trim();
                                  _doctor['specialization'] = specCtrl.text
                                      .trim();
                                  _doctor['clinicName'] = clinicCtrl.text
                                      .trim();
                                  _doctor['phone'] = phoneCtrl.text.trim();
                                  _doctor['workingHours'] = hoursCtrl.text
                                      .trim();
                                  _doctor['breakTime'] = breakCtrl.text.trim();
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Profile updated successfully',
                                      style: GoogleFonts.sora(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                    backgroundColor: AppTheme.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withAlpha(60),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Save Changes',
                                    style: GoogleFonts.sora(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> workingDays = List<String>.from(
      _doctor['workingDays'] as List,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                color: AppTheme.surfaceLight,
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile',
                      style: GoogleFonts.sora(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    TextButton(
                      onPressed: _openEditProfile,
                      child: Text(
                        'Edit',
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              // Avatar + name section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outlineVariantLight),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withAlpha(10),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _doctor['initials'] as String,
                          style: GoogleFonts.sora(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _doctor['name'] as String,
                            style: GoogleFonts.sora(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _doctor['specialization'] as String,
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _doctor['inboundPhone'] as String,
                              style: GoogleFonts.sora(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              // Clinic section
              _SectionCard(
                title: 'Clinic',
                children: [
                  _InfoTile(
                    icon: Icons.local_hospital_outlined,
                    label: 'Clinic Name',
                    value: _doctor['clinicName'] as String,
                  ),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: _doctor['clinicAddress'] as String,
                  ),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _doctor['email'] as String,
                  ),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: _doctor['phone'] as String,
                    isLast: true,
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              // Availability section
              _SectionCard(
                title: 'Availability',
                children: [
                  _InfoTile(
                    icon: Icons.access_time_outlined,
                    label: 'Working Hours',
                    value: _doctor['workingHours'] as String,
                  ),
                  _InfoTile(
                    icon: Icons.free_breakfast_outlined,
                    label: 'Break Time',
                    value: _doctor['breakTime'] as String,
                  ),
                  // Working days
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppTheme.mutedLight,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Working Days',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            color: AppTheme.mutedLight,
                          ),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 4,
                          children: _allDays.map((day) {
                            final isActive = workingDays.contains(day);
                            return Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.primary
                                    : AppTheme.surfaceVariantLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  day[0],
                                  style: GoogleFonts.sora(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.mutedLight,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  // Vacation mode
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.beach_access_outlined,
                          size: 18,
                          color: AppTheme.mutedLight,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vacation Mode',
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceLight,
                                ),
                              ),
                              Text(
                                'Pause all new bookings',
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  color: AppTheme.mutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _vacationMode,
                          onChanged: (v) => setState(() => _vacationMode = v),
                          activeThumbColor: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              // Preferences section
              _SectionCard(
                title: 'Preferences',
                children: [
                  _ToggleTile(
                    icon: Icons.notifications_outlined,
                    label: 'Push Notifications',
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  _ToggleTile(
                    icon: Icons.sms_outlined,
                    label: 'SMS Notifications',
                    value: _smsNotifications,
                    onChanged: (v) => setState(() => _smsNotifications = v),
                  ),
                  _ToggleTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    isLast: true,
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              // Sign out
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.loginScreen),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.error.withAlpha(60)),
                    ),
                    child: Center(
                      child: Text(
                        'Sign Out',
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedLight,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.sora(fontSize: 14, color: AppTheme.onSurfaceLight),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppTheme.mutedLight),
            hintText: hint,
            hintStyle: GoogleFonts.sora(
              fontSize: 13,
              color: AppTheme.outlineLight,
            ),
            filled: true,
            fillColor: AppTheme.backgroundLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.outlineVariantLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.outlineVariantLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariantLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.mutedLight),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppTheme.mutedLight,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceLight,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 46,
            color: AppTheme.outlineVariantLight,
          ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.mutedLight),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppTheme.primary,
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 46,
            color: AppTheme.outlineVariantLight,
          ),
      ],
    );
  }
}
