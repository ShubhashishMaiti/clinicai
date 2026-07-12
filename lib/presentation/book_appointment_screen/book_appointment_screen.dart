import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? prefilledPatient;

  const BookAppointmentScreen({super.key, this.prefilledPatient});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  int _currentStep = 0;
  bool _isNewPatient = false;
  Map<String, dynamic>? _selectedPatient;
  DateTime? _selectedDate;
  String? _selectedSlot;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();
  final TextEditingController _newAgeController = TextEditingController();
  String _newGender = 'Male';
  bool _isBooking = false;
  bool _bookingSuccess = false;

  final List<Map<String, dynamic>> _existingPatients = [
    {
      'id': 'p1',
      'name': 'Priya Sharma',
      'phone': '+1 (415) 555-0201',
      'initials': 'PS',
      'color': const Color(0xFF2563EB),
    },
    {
      'id': 'p2',
      'name': 'James Okafor',
      'phone': '+1 (415) 555-0202',
      'initials': 'JO',
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'p3',
      'name': 'Maria Gonzalez',
      'phone': '+1 (415) 555-0203',
      'initials': 'MG',
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'p4',
      'name': 'David Chen',
      'phone': '+1 (415) 555-0204',
      'initials': 'DC',
      'color': const Color(0xFFEF4444),
    },
    {
      'id': 'p5',
      'name': 'Aisha Patel',
      'phone': '+1 (415) 555-0205',
      'initials': 'AP',
      'color': const Color(0xFF8B5CF6),
    },
  ];

  final List<String> _timeSlots = [
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '2:00 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
    '4:30 PM',
  ];

  final List<bool> _slotAvailable = [
    true,
    false,
    true,
    true,
    false,
    true,
    true,
    true,
    false,
    true,
    true,
    false,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledPatient != null) {
      _selectedPatient = widget.prefilledPatient;
    }
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _newNameController.dispose();
    _newPhoneController.dispose();
    _newAgeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isBooking = false;
        _bookingSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context);
    }
  }

  bool get _canProceedStep0 {
    if (_isNewPatient) {
      return _newNameController.text.isNotEmpty &&
          _newPhoneController.text.isNotEmpty;
    }
    return _selectedPatient != null;
  }

  bool get _canProceedStep1 => _selectedDate != null && _selectedSlot != null;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                if (_currentStep > 0)
                  GestureDetector(
                    onTap: _prevStep,
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: AppTheme.onSurfaceLight,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 22,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                const Spacer(),
                Text(
                  'Book Appointment',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 22),
              ],
            ),
          ),
          // Progress dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final isActive = i <= _currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary : AppTheme.outlineLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          // Step labels
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                _StepLabel(label: 'Patient', index: 0, current: _currentStep),
                const Expanded(
                  child: Divider(color: AppTheme.outlineVariantLight),
                ),
                _StepLabel(
                  label: 'Date & Slot',
                  index: 1,
                  current: _currentStep,
                ),
                const Expanded(
                  child: Divider(color: AppTheme.outlineVariantLight),
                ),
                _StepLabel(label: 'Confirm', index: 2, current: _currentStep),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Step content
          Expanded(
            child: _bookingSuccess
                ? _buildSuccess()
                : IndexedStack(
                    index: _currentStep,
                    children: [_buildStep0(), _buildStep1(), _buildStep2()],
                  ),
          ),
          // Bottom button
          if (!_bookingSuccess)
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 3.h),
              child: GestureDetector(
                onTap: () {
                  if (_currentStep == 0 && _canProceedStep0) _nextStep();
                  if (_currentStep == 1 && _canProceedStep1) _nextStep();
                  if (_currentStep == 2) _confirmBooking();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color:
                        (_currentStep == 0 && !_canProceedStep0) ||
                            (_currentStep == 1 && !_canProceedStep1)
                        ? AppTheme.outlineLight
                        : AppTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isBooking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'Confirm Booking' : 'Continue',
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Patient',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose an existing patient or add a new one',
            style: GoogleFonts.sora(fontSize: 13, color: AppTheme.mutedLight),
          ),
          SizedBox(height: 2.h),
          // Toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isNewPatient = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isNewPatient
                          ? AppTheme.primary
                          : AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Existing Patient',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !_isNewPatient
                              ? Colors.white
                              : AppTheme.mutedLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isNewPatient = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isNewPatient
                          ? AppTheme.primary
                          : AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '+ New Patient',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isNewPatient
                              ? Colors.white
                              : AppTheme.mutedLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (!_isNewPatient) ...[
            ..._existingPatients.map((p) {
              final isSelected = _selectedPatient?['id'] == p['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedPatient = p),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineVariantLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (p['color'] as Color).withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            p['initials'] as String,
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: p['color'] as Color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'] as String,
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceLight,
                              ),
                            ),
                            Text(
                              p['phone'] as String,
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                color: AppTheme.mutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            TextField(
              controller: _newNameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPhoneController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newAgeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _newGender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _newGender = v!),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick a Date & Time',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          SizedBox(height: 2.h),
          // Mini calendar
          _buildMiniCalendar(),
          SizedBox(height: 2.h),
          Text(
            'Available Slots',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            itemCount: _timeSlots.length,
            itemBuilder: (context, i) {
              final isAvailable = _slotAvailable[i];
              final isSelected = _selectedSlot == _timeSlots[i];
              return GestureDetector(
                onTap: isAvailable
                    ? () => setState(() => _selectedSlot = _timeSlots[i])
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : isAvailable
                        ? AppTheme.surfaceVariantLight
                        : AppTheme.outlineVariantLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineVariantLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _timeSlots[i],
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isAvailable
                            ? AppTheme.onSurfaceLight
                            : AppTheme.mutedLight,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar() {
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected =
              _selectedDate != null &&
              _selectedDate!.day == day.day &&
              _selectedDate!.month == day.month;
          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final dayName = dayNames[day.weekday - 1];

          return GestureDetector(
            onTap: () => setState(() {
              _selectedDate = day;
              _selectedSlot = null;
            }),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.outlineVariantLight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white.withAlpha(200)
                          : AppTheme.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.onSurfaceLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep2() {
    final patientName = _isNewPatient
        ? _newNameController.text
        : (_selectedPatient?['name'] as String? ?? '');
    final patientPhone = _isNewPatient
        ? _newPhoneController.text
        : (_selectedPatient?['phone'] as String? ?? '');

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Booking',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withAlpha(60)),
            ),
            child: Column(
              children: [
                _ConfirmRow(
                  icon: Icons.person_outline,
                  label: 'Patient',
                  value: patientName,
                ),
                const Divider(height: 20, color: AppTheme.outlineVariantLight),
                _ConfirmRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: patientPhone,
                ),
                const Divider(height: 20, color: AppTheme.outlineVariantLight),
                _ConfirmRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : '—',
                ),
                const Divider(height: 20, color: AppTheme.outlineVariantLight),
                _ConfirmRow(
                  icon: Icons.access_time_outlined,
                  label: 'Time',
                  value: _selectedSlot ?? '—',
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Reason for Visit',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe the reason for this appointment…',
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppTheme.success, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'Appointment Booked!',
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The patient will receive an SMS confirmation.',
            style: GoogleFonts.sora(fontSize: 14, color: AppTheme.mutedLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String label;
  final int index;
  final int current;

  const _StepLabel({
    required this.label,
    required this.index,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index <= current;
    return Text(
      label,
      style: GoogleFonts.sora(
        fontSize: 11,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive ? AppTheme.primary : AppTheme.mutedLight,
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.sora(fontSize: 13, color: AppTheme.mutedLight),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceLight,
          ),
        ),
      ],
    );
  }
}
