import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ApiService().listDoctors();
      if (mounted) {
        setState(() {
          _doctors = list
              .map((d) => Map<String, dynamic>.from(d as Map))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              e.toString().contains('connectionError') ||
                  e.toString().contains('SocketException') ||
                  e.toString().contains('reach server')
              ? 'Could not reach the server. Please check your connection and try again.'
              : 'Failed to load doctors. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _openAddDoctor() {
    _openDoctorForm(null);
  }

  void _openEditDoctor(Map<String, dynamic> doctor) {
    _openDoctorForm(doctor);
  }

  void _openDoctorForm(Map<String, dynamic>? existing) {
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final clinicCtrl = TextEditingController(
      text: existing?['clinic_name'] ?? '',
    );
    final clinicAddrCtrl = TextEditingController(
      text: existing?['clinic_address'] ?? '',
    );
    final specCtrl = TextEditingController(
      text: existing?['specialization'] ?? '',
    );
    final inboundPhoneCtrl = TextEditingController(
      text: existing?['inbound_phone'] ?? '',
    );
    final calUsernameCtrl = TextEditingController(
      text: existing?['cal_username'] ?? '',
    );
    final calEventTypeCtrl = TextEditingController(
      text: existing?['cal_event_type_id'] ?? '',
    );

    // Parse working hours
    String whStart = '09:00';
    String whEnd = '17:00';
    final rawHours = existing?['working_hours'];
    if (rawHours is Map) {
      whStart = rawHours['start'] ?? '09:00';
      whEnd = rawHours['end'] ?? '17:00';
    }
    final whStartCtrl = TextEditingController(text: whStart);
    final whEndCtrl = TextEditingController(text: whEnd);

    // Parse working days
    List<String> selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final rawDays = existing?['working_days'];
    if (rawDays is List) {
      selectedDays = rawDays.map((d) => d.toString()).toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            bool isSubmitting = false;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                height: 90.h,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
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
                              color: isEdit
                                  ? const Color(0xFFFEF3C7)
                                  : AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isEdit
                                  ? Icons.edit_outlined
                                  : Icons.person_add_outlined,
                              size: 18,
                              color: isEdit
                                  ? const Color(0xFFD97706)
                                  : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Doctor' : 'Onboard New Doctor',
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
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormSectionLabel(label: 'Account'),
                            const SizedBox(height: 10),
                            _AdminField(
                              label: 'Full Name *',
                              controller: nameCtrl,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            _AdminField(
                              label: isEdit ? 'Email (read-only)' : 'Email *',
                              controller: emailCtrl,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: isEdit,
                            ),
                            const SizedBox(height: 12),
                            _AdminField(
                              label: isEdit
                                  ? 'New Password (leave blank to keep)'
                                  : 'Password *',
                              controller: passwordCtrl,
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            const SizedBox(height: 20),
                            _FormSectionLabel(label: 'Doctor Details'),
                            const SizedBox(height: 10),
                            _AdminField(
                              label: 'Specialization',
                              controller: specCtrl,
                              icon: Icons.medical_services_outlined,
                            ),
                            const SizedBox(height: 12),
                            _AdminField(
                              label: 'Phone',
                              controller: phoneCtrl,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 20),
                            _FormSectionLabel(label: 'Clinic'),
                            const SizedBox(height: 10),
                            _AdminField(
                              label: 'Clinic Name',
                              controller: clinicCtrl,
                              icon: Icons.local_hospital_outlined,
                            ),
                            const SizedBox(height: 12),
                            _AdminField(
                              label: 'Clinic Address',
                              controller: clinicAddrCtrl,
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 20),
                            _FormSectionLabel(label: 'Working Hours'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _AdminField(
                                    label: 'Start (HH:MM)',
                                    controller: whStartCtrl,
                                    icon: Icons.access_time_outlined,
                                    hint: '09:00',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AdminField(
                                    label: 'End (HH:MM)',
                                    controller: whEndCtrl,
                                    icon: Icons.access_time_filled_outlined,
                                    hint: '17:00',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _FormSectionLabel(label: 'Working Days'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ].map((day) {
                                    final isSelected = selectedDays.contains(
                                      day,
                                    );
                                    return GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          if (isSelected) {
                                            selectedDays.remove(day);
                                          } else {
                                            selectedDays.add(day);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.backgroundLight,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primary
                                                : AppTheme.outlineVariantLight,
                                          ),
                                        ),
                                        child: Text(
                                          day,
                                          style: GoogleFonts.sora(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : AppTheme.mutedLight,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 20),
                            _FormSectionLabel(label: 'Vapi / Inbound Phone'),
                            const SizedBox(height: 10),
                            _AdminField(
                              label: 'Inbound Phone',
                              controller: inboundPhoneCtrl,
                              icon: Icons.phone_in_talk_outlined,
                              keyboardType: TextInputType.phone,
                              hint: 'e.g. +14155550101',
                            ),
                            const SizedBox(height: 20),
                            _FormSectionLabel(label: 'Cal.com Integration'),
                            const SizedBox(height: 10),
                            _AdminField(
                              label: 'Cal.com Username',
                              controller: calUsernameCtrl,
                              icon: Icons.calendar_today_outlined,
                            ),
                            const SizedBox(height: 12),
                            _AdminField(
                              label: 'Cal.com Event Type ID',
                              controller: calEventTypeCtrl,
                              icon: Icons.event_outlined,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 28),
                            // Submit button
                            StatefulBuilder(
                              builder: (_, setSaveState) {
                                return GestureDetector(
                                  onTap: isSubmitting
                                      ? null
                                      : () async {
                                          final name = nameCtrl.text.trim();
                                          final email = emailCtrl.text.trim();
                                          final password = passwordCtrl.text
                                              .trim();
                                          if (name.isEmpty || email.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              _errorSnack(
                                                'Name and email are required',
                                              ),
                                            );
                                            return;
                                          }
                                          if (!isEdit && password.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              _errorSnack(
                                                'Password is required for new doctors',
                                              ),
                                            );
                                            return;
                                          }
                                          setSaveState(
                                            () => isSubmitting = true,
                                          );
                                          try {
                                            final payload = <String, dynamic>{
                                              'name': name,
                                              'email': email,
                                              'phone': phoneCtrl.text.trim(),
                                              'clinic_name': clinicCtrl.text
                                                  .trim(),
                                              'clinic_address': clinicAddrCtrl
                                                  .text
                                                  .trim(),
                                              'specialization': specCtrl.text
                                                  .trim(),
                                              'inbound_phone': inboundPhoneCtrl
                                                  .text
                                                  .trim(),
                                              'cal_username': calUsernameCtrl
                                                  .text
                                                  .trim(),
                                              'cal_event_type_id':
                                                  calEventTypeCtrl.text.trim(),
                                              'working_hours': {
                                                'start':
                                                    whStartCtrl.text
                                                        .trim()
                                                        .isEmpty
                                                    ? '09:00'
                                                    : whStartCtrl.text.trim(),
                                                'end':
                                                    whEndCtrl.text
                                                        .trim()
                                                        .isEmpty
                                                    ? '17:00'
                                                    : whEndCtrl.text.trim(),
                                              },
                                              'working_days': selectedDays,
                                            };
                                            if (password.isNotEmpty) {
                                              payload['password'] = password;
                                            }

                                            if (isEdit) {
                                              final doctorId =
                                                  existing['doctor_id']
                                                      as String? ??
                                                  '';
                                              await ApiService().updateDoctor(
                                                doctorId,
                                                payload,
                                              );
                                            } else {
                                              await ApiService().onboardDoctor(
                                                payload,
                                              );
                                            }

                                            if (ctx.mounted) Navigator.pop(ctx);
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                _successSnack(
                                                  isEdit
                                                      ? 'Doctor updated successfully'
                                                      : 'Doctor onboarded successfully',
                                                ),
                                              );
                                              _loadDoctors();
                                            }
                                          } catch (e) {
                                            setSaveState(
                                              () => isSubmitting = false,
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                _errorSnack(
                                                  isEdit
                                                      ? 'Failed to update doctor'
                                                      : 'Failed to onboard doctor',
                                                ),
                                              );
                                            }
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
                                                color: AppTheme.primary
                                                    .withAlpha(60),
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
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              isEdit
                                                  ? 'Save Changes'
                                                  : 'Onboard Doctor',
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
      },
    );
  }

  Future<void> _confirmDeleteDoctor(Map<String, dynamic> doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Doctor',
          style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to remove ${doctor['name']}? This action cannot be undone.',
          style: GoogleFonts.sora(fontSize: 14, color: AppTheme.mutedLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(color: AppTheme.mutedLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: GoogleFonts.sora(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final doctorId = doctor['doctor_id'] as String? ?? '';
        await ApiService().deleteDoctor(doctorId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(_successSnack('Doctor removed successfully'));
          _loadDoctors();
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(_errorSnack('Failed to remove doctor'));
        }
      }
    }
  }

  SnackBar _successSnack(String msg) => SnackBar(
    content: Text(
      msg,
      style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
    ),
    backgroundColor: AppTheme.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  );

  SnackBar _errorSnack(String msg) => SnackBar(
    content: Text(
      msg,
      style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
    ),
    backgroundColor: AppTheme.error,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppTheme.onSurfaceLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
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
              'Admin Panel',
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_outlined,
              size: 20,
              color: AppTheme.mutedLight,
            ),
            onPressed: _loadDoctors,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.outlineVariantLight),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDoctor,
        backgroundColor: AppTheme.primary,
        icon: const Icon(
          Icons.person_add_outlined,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'Add Doctor',
          style: GoogleFonts.sora(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDoctors,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.sora(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : _doctors.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No doctors yet',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add Doctor" to onboard your first doctor',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 12.h),
              children: [
                // Stats header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_doctors.length} Doctor${_doctors.length == 1 ? '' : 's'}',
                            style: GoogleFonts.sora(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Registered in the system',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Doctor cards
                ..._doctors.map(
                  (doctor) => _DoctorCard(
                    doctor: doctor,
                    onEdit: () => _openEditDoctor(doctor),
                    onDelete: () => _confirmDeleteDoctor(doctor),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DoctorCard({
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = doctor['name'] as String? ?? 'Unknown';
    final email = doctor['email'] as String? ?? '';
    final spec = doctor['specialization'] as String? ?? '';
    final phone = doctor['phone'] as String? ?? '';
    final clinicName = doctor['clinic_name'] as String? ?? '';
    final inboundPhone = doctor['inbound_phone'] as String? ?? '';
    final calUsername = doctor['cal_username'] as String? ?? '';
    final isAdmin = doctor['is_admin'] as bool? ?? false;

    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ADMIN',
                                style: GoogleFonts.sora(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (spec.isNotEmpty)
                        Text(
                          spec,
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                      Text(
                        email,
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: AppTheme.mutedLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      tooltip: 'Edit',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    if (!isAdmin)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.error,
                        ),
                        tooltip: 'Remove',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Details
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(height: 1, color: AppTheme.outlineVariantLight),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (phone.isNotEmpty)
                      _InfoChip(icon: Icons.phone_outlined, label: phone),
                    if (clinicName.isNotEmpty)
                      _InfoChip(
                        icon: Icons.local_hospital_outlined,
                        label: clinicName,
                      ),
                    if (inboundPhone.isNotEmpty)
                      _InfoChip(
                        icon: Icons.phone_in_talk_outlined,
                        label: inboundPhone,
                        color: const Color(0xFF059669),
                        bgColor: const Color(0xFFD1FAE5),
                      ),
                    if (calUsername.isNotEmpty)
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: calUsername,
                        color: AppTheme.primary,
                        bgColor: AppTheme.primaryContainer,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color? bgColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.mutedLight;
    final bg = bgColor ?? AppTheme.backgroundLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 11,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

class _AdminField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool readOnly;

  const _AdminField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.isPassword = false,
    this.readOnly = false,
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
          readOnly: readOnly,
          style: GoogleFonts.sora(
            fontSize: 14,
            color: readOnly ? AppTheme.mutedLight : AppTheme.onSurfaceLight,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppTheme.mutedLight),
            hintText: hint,
            hintStyle: GoogleFonts.sora(
              fontSize: 13,
              color: AppTheme.outlineLight,
            ),
            filled: true,
            fillColor: readOnly
                ? AppTheme.backgroundLight.withAlpha(180)
                : AppTheme.backgroundLight,
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
              borderSide: BorderSide(
                color: readOnly
                    ? AppTheme.outlineVariantLight
                    : AppTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
