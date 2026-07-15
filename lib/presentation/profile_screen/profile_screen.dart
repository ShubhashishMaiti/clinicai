import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
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
  bool _isLoading = true;

  Map<String, dynamic> _doctor = {
    'name': '',
    'specialization': '',
    'email': '',
    'phone': '',
    'clinicName': '',
    'clinicAddress': '',
    'inboundPhone': '',
    'workingHours': '',
    'workingDays': <String>[],
    'breakTime': '',
    'initials': '',
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService().getProfile();
      final name = (data['name'] as String? ?? '');
      final parts = name.trim().split(' ');
      final initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : name.isNotEmpty
          ? name[0].toUpperCase()
          : '?';

      // Parse working days
      List<String> workingDays = [];
      final rawDays = data['working_days'];
      if (rawDays is List) {
        workingDays = rawDays.map((d) => d.toString()).toList();
      } else if (rawDays is Map) {
        final dayMap = rawDays as Map<String, dynamic>;
        const dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        for (int i = 0; i < dayKeys.length; i++) {
          if (dayMap[dayKeys[i]] == true) workingDays.add(dayLabels[i]);
        }
      }

      // Parse working hours
      String workingHours = '';
      final rawHours = data['working_hours'];
      if (rawHours is Map) {
        final start = rawHours['start'] ?? '';
        final end = rawHours['end'] ?? '';
        workingHours = '$start – $end';
      } else if (rawHours is String) {
        workingHours = rawHours;
      }

      if (mounted) {
        setState(() {
          _doctor = {
            'name': name,
            'specialization': data['specialization'] as String? ?? '',
            'email': data['email'] as String? ?? '',
            'phone': data['phone'] as String? ?? '',
            'clinicName': data['clinic_name'] as String? ?? '',
            'clinicAddress': data['clinic_address'] as String? ?? '',
            'inboundPhone': data['inbound_phone'] as String? ?? '',
            'workingHours': workingHours,
            'workingDays': workingDays,
            'breakTime': data['break_time'] as String? ?? '',
            'initials': initials,
            'isAdmin': data['is_admin'] as bool? ?? false,
          };
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  void _openOnboardDoctor() {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final clinicCtrl = TextEditingController();
    final clinicAddrCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final inboundPhoneCtrl = TextEditingController();
    final calUsernameCtrl = TextEditingController();
    final calEventTypeCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_add_outlined,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Onboard New Doctor',
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
                    const Divider(
                      height: 1,
                      color: AppTheme.outlineVariantLight,
                    ),
                    // Fields
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormSectionLabel(label: 'Account'),
                            const SizedBox(height: 10),
                            _EditField(
                              label: 'Full Name *',
                              controller: nameCtrl,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            _EditField(
                              label: 'Email *',
                              controller: emailCtrl,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _EditField(
                              label: 'Password *',
                              controller: passwordCtrl,
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            const SizedBox(height: 20),
                            _FormSectionLabel(label: 'Doctor Details'),
                            const SizedBox(height: 10),
                            _EditField(
                              label: 'Specialization',
                              controller: specCtrl,
                              icon: Icons.medical_services_outlined,
                            ),
                            const SizedBox(height: 12),
                            _EditField(
                              label: 'Phone',
                              controller: phoneCtrl,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 20),
                            _FormSectionLabel(label: 'Clinic'),
                            const SizedBox(height: 10),
                            _EditField(
                              label: 'Clinic Name',
                              controller: clinicCtrl,
                              icon: Icons.local_hospital_outlined,
                            ),
                            const SizedBox(height: 12),
                            _EditField(
                              label: 'Clinic Address',
                              controller: clinicAddrCtrl,
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 20),
                            _FormSectionLabel(label: 'Vapi / Inbound Phone'),
                            const SizedBox(height: 10),
                            _EditField(
                              label: 'Inbound Phone *',
                              controller: inboundPhoneCtrl,
                              icon: Icons.phone_in_talk_outlined,
                              keyboardType: TextInputType.phone,
                              hint: 'e.g. +14155550101',
                            ),
                            const SizedBox(height: 20),
                            _FormSectionLabel(label: 'Cal.com Integration'),
                            const SizedBox(height: 10),
                            _EditField(
                              label: 'Cal.com Username',
                              controller: calUsernameCtrl,
                              icon: Icons.calendar_today_outlined,
                            ),
                            const SizedBox(height: 12),
                            _EditField(
                              label: 'Cal.com Event Type ID',
                              controller: calEventTypeCtrl,
                              icon: Icons.event_outlined,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 28),
                            // Submit button
                            GestureDetector(
                              onTap: isSubmitting
                                  ? null
                                  : () async {
                                      final email = emailCtrl.text.trim();
                                      final password = passwordCtrl.text.trim();
                                      final name = nameCtrl.text.trim();
                                      if (email.isEmpty ||
                                          password.isEmpty ||
                                          name.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Name, email and password are required',
                                              style: GoogleFonts.sora(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                            backgroundColor: AppTheme.error,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                        return;
                                      }
                                      setSheetState(() => isSubmitting = true);
                                      try {
                                        await ApiService().onboardDoctor({
                                          'email': email,
                                          'password': password,
                                          'name': name,
                                          'phone': phoneCtrl.text.trim(),
                                          'clinic_name': clinicCtrl.text.trim(),
                                          'clinic_address': clinicAddrCtrl.text
                                              .trim(),
                                          'specialization': specCtrl.text
                                              .trim(),
                                          'inbound_phone': inboundPhoneCtrl.text
                                              .trim(),
                                          'cal_username': calUsernameCtrl.text
                                              .trim(),
                                          'cal_event_type_id': calEventTypeCtrl
                                              .text
                                              .trim(),
                                        });
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                        }
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Doctor onboarded successfully',
                                                style: GoogleFonts.sora(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              backgroundColor: AppTheme.success,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (_) {
                                        setSheetState(
                                          () => isSubmitting = false,
                                        );
                                      }
                                    },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isSubmitting
                                      ? AppTheme.primary.withAlpha(120)
                                      : AppTheme.primary,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isSubmitting
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: AppTheme.primary.withAlpha(
                                              60,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Onboard Doctor',
                                          style: GoogleFonts.sora(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> workingDays = List<String>.from(
      _doctor['workingDays'] as List,
    );
    final bool isAdmin = _doctor['isAdmin'] as bool? ?? false;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

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
                          Row(
                            children: [
                              if ((_doctor['inboundPhone'] as String)
                                  .isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.phone_in_talk_outlined,
                                        size: 11,
                                        color: AppTheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _doctor['inboundPhone'] as String,
                                        style: GoogleFonts.sora(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: GoogleFonts.sora(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                            ],
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
                  ),
                  _InfoTile(
                    icon: Icons.phone_in_talk_outlined,
                    label: 'Inbound Phone',
                    value: (_doctor['inboundPhone'] as String).isNotEmpty
                        ? _doctor['inboundPhone'] as String
                        : 'Not configured',
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
              // Admin section — only visible when is_admin=true
              if (isAdmin) ...[
                SizedBox(height: 2.h),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD97706).withAlpha(80),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withAlpha(12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 16,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ADMIN',
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD97706),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        color: AppTheme.outlineVariantLight,
                      ),
                      // Manage Doctors tile
                      InkWell(
                        onTap: () => context.push(AppRoutes.adminScreen),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.people_outlined,
                                  size: 20,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manage Doctors',
                                      style: GoogleFonts.sora(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurfaceLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'View, add, edit & remove doctors',
                                      style: GoogleFonts.sora(
                                        fontSize: 12,
                                        color: AppTheme.mutedLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: AppTheme.mutedLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        color: AppTheme.outlineVariantLight,
                      ),
                      // Onboard Doctor tile
                      InkWell(
                        onTap: _openOnboardDoctor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person_add_outlined,
                                  size: 20,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Onboard Doctor',
                                      style: GoogleFonts.sora(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurfaceLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Add a new doctor with inbound phone & Cal.com',
                                      style: GoogleFonts.sora(
                                        fontSize: 12,
                                        color: AppTheme.mutedLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: AppTheme.mutedLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
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

class _FormSectionLabel extends StatelessWidget {
  final String label;
  const _FormSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.mutedLight,
        letterSpacing: 0.8,
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
  final bool isPassword;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.isPassword = false,
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
          obscureText: isPassword,
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
