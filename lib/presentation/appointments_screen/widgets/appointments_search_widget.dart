import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class AppointmentsSearchWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const AppointmentsSearchWidget({required this.onChanged, super.key});

  @override
  State<AppointmentsSearchWidget> createState() =>
      _AppointmentsSearchWidgetState();
}

class _AppointmentsSearchWidgetState extends State<AppointmentsSearchWidget> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outlineLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            CustomIconWidget(
              iconName: 'search',
              color: AppTheme.mutedLight,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppTheme.onSurfaceLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Search patients, reasons...',
                  hintStyle: GoogleFonts.sora(
                    fontSize: 13,
                    color: AppTheme.mutedLight,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
              ),
            ),
            if (_hasText)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.mutedLight,
                    size: 16,
                  ),
                ),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
