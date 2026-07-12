import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../book_appointment_screen/book_appointment_screen.dart';

class _QuickAction {
  final String label;
  final String iconName;
  final Color color;
  final Color bgColor;
  final void Function(BuildContext context)? onTap;

  const _QuickAction({
    required this.label,
    required this.iconName,
    required this.color,
    required this.bgColor,
    this.onTap,
  });
}

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  void _openBookAppointment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookAppointmentScreen(),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Book Appointment',
        iconName: 'calendar_add_on',
        color: AppTheme.primary,
        bgColor: AppTheme.primaryContainer,
        onTap: (ctx) => _openBookAppointment(ctx),
      ),
      _QuickAction(
        label: 'Block Slot',
        iconName: 'block',
        color: AppTheme.error,
        bgColor: AppTheme.errorContainer,
        onTap: (ctx) => _showSnackbar(ctx, 'Block Slot — coming soon'),
      ),
      _QuickAction(
        label: 'Search Records',
        iconName: 'search',
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFEDE9FE),
        onTap: (ctx) => _showSnackbar(ctx, 'Search Records — coming soon'),
      ),
      _QuickAction(
        label: 'Notifications',
        iconName: 'notifications_outlined',
        color: AppTheme.warning,
        bgColor: AppTheme.warningContainer,
        onTap: (ctx) => _showSnackbar(ctx, 'Notifications — coming soon'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      children: actions.map((a) => _QuickActionTile(action: a)).toList(),
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  final _QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.action.onTap?.call(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.action.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: widget.action.iconName,
                    color: widget.action.color,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.action.label,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
