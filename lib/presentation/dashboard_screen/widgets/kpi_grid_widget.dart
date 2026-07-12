import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

// TODO: Replace with [Riverpod/Bloc] for production state

class KpiGridWidget extends StatelessWidget {
  final Map<String, int> kpiData;

  const KpiGridWidget({required this.kpiData, super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final items = [
      _KpiItem(
        label: "Today's Appts",
        value: kpiData['today'] ?? 0,
        iconName: 'today',
        color: AppTheme.primary,
        bgColor: AppTheme.primaryContainer,
        subtitle: 'Scheduled for today',
      ),
      _KpiItem(
        label: 'Upcoming',
        value: kpiData['upcoming'] ?? 0,
        iconName: 'upcoming',
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFEDE9FE),
        subtitle: 'Next 7 days',
      ),
      _KpiItem(
        label: 'Completed',
        value: kpiData['completed'] ?? 0,
        iconName: 'check_circle_outline',
        color: AppTheme.success,
        bgColor: AppTheme.successContainer,
        subtitle: 'Today so far',
      ),
      _KpiItem(
        label: 'Pending',
        value: kpiData['pending'] ?? 0,
        iconName: 'pending_outlined',
        color: AppTheme.warning,
        bgColor: AppTheme.warningContainer,
        subtitle: 'Needs attention',
        isAlert: (kpiData['pending'] ?? 0) > 0,
      ),
    ];

    if (isTablet) {
      return Row(
        children: items.map((item) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: items.indexOf(item) < items.length - 1 ? 10 : 0,
              ),
              child: _KpiTileWidget(item: item),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _KpiTileWidget(item: items[0])),
            const SizedBox(width: 10),
            Expanded(child: _KpiTileWidget(item: items[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _KpiTileWidget(item: items[2])),
            const SizedBox(width: 10),
            Expanded(child: _KpiTileWidget(item: items[3])),
          ],
        ),
      ],
    );
  }
}

class _KpiItem {
  final String label;
  final int value;
  final String iconName;
  final Color color;
  final Color bgColor;
  final String subtitle;
  final bool isAlert;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.iconName,
    required this.color,
    required this.bgColor,
    required this.subtitle,
    this.isAlert = false,
  });
}

class _KpiTileWidget extends StatefulWidget {
  final _KpiItem item;

  const _KpiTileWidget({required this.item});

  @override
  State<_KpiTileWidget> createState() => _KpiTileWidgetState();
}

class _KpiTileWidgetState extends State<_KpiTileWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _countAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _countAnim = IntTween(
      begin: 0,
      end: widget.item.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: widget.item.isAlert
            ? Border.all(color: widget.item.color.withAlpha(77), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.item.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: widget.item.iconName,
                    color: widget.item.color,
                    size: 18,
                  ),
                ),
              ),
              if (widget.item.isAlert)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.item.color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _countAnim,
            builder: (context, _) => Text(
              '${_countAnim.value}',
              style: GoogleFonts.sora(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: widget.item.color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.item.label,
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.item.subtitle,
            style: GoogleFonts.sora(fontSize: 11, color: AppTheme.mutedLight),
          ),
        ],
      ),
    );
  }
}
