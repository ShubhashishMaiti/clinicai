import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class WeeklyChartWidget extends StatelessWidget {
  const WeeklyChartWidget({super.key});

  // TODO: Replace with [Riverpod/Bloc] real weekly appointment data from /api/dashboard/summary
  static const List<Map<String, dynamic>> _weekData = [
    {'day': 'Mon', 'count': 6.0},
    {'day': 'Tue', 'count': 9.0},
    {'day': 'Wed', 'count': 7.0},
    {'day': 'Thu', 'count': 11.0},
    {'day': 'Fri', 'count': 8.0},
    {'day': 'Sat', 'count': 5.0},
    {'day': 'Sun', 'count': 2.0},
  ];

  @override
  Widget build(BuildContext context) {
    const todayIndex = 5; // Saturday

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Appointments',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  Text(
                    'Jul 7 – Jul 13, 2026',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '48 total',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 14,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} appts',
                        GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _weekData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _weekData[idx]['day'] as String,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: idx == todayIndex
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: idx == todayIndex
                                  ? AppTheme.primary
                                  : AppTheme.mutedLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.outlineVariantLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  _weekData.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (_weekData[i]['count'] as double),
                        width: 24,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        color: i == todayIndex
                            ? AppTheme.primary
                            : AppTheme.primaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
