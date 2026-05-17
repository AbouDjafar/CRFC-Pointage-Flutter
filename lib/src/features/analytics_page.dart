import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/widgets.dart';
import '../data/app_controller.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider.notifier);
    final snapshot = controller.analyticsSnapshot(
      start: _month,
      end: DateTime(_month.year, _month.month + 1, 0),
    );

    return CrfcPageScaffold(
      title: 'Vue d\'ensemble',
      subtitle: 'STATISTIQUES & ANALYSE',
      leading: IconButton(
        onPressed: () => context.go('/dashboard'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      trailing: IconButton(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _month,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            locale: const Locale('fr'),
          );
          if (picked != null) {
            setState(() => _month = DateTime(picked.year, picked.month, 1));
          }
        },
        icon: const Icon(Icons.filter_alt_outlined),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrfcCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatMonthYear(_month),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const Icon(Icons.calendar_month_rounded),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
            children: [
              CrfcStatCard(
                title: 'INCIDENTS',
                value: '${snapshot.totalIncidents}',
                subtitle: '+12%',
                icon: Icons.trending_up_rounded,
                iconColor: Colors.redAccent,
              ),
              CrfcStatCard(
                title: 'VISITEURS',
                value: '${snapshot.totalVisitors}',
                subtitle: '+5%',
                icon: Icons.trending_up_rounded,
                iconColor: Colors.green,
              ),
              CrfcStatCard(
                title: 'RETARD MOYEN',
                value: '${snapshot.averageLateMinutes.round()} min',
                subtitle: '-2 min',
                icon: Icons.schedule_rounded,
                iconColor: Colors.green,
              ),
              CrfcStatCard(
                title: 'RAPPORTS',
                value: '${snapshot.reportCount}',
                subtitle: 'Stables',
                icon: Icons.description_rounded,
                iconColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'Tendance des incidents',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 26),
            ),
          ),
          const SizedBox(height: 16),
          CrfcCard(
            child: SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: const Color(0xFFC67D1B),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0x30C67D1B),
                      ),
                      spots: [
                        for (var i = 0; i < snapshot.trendPoints.length; i++)
                          FlSpot(i.toDouble(), snapshot.trendPoints[i].value),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= snapshot.trendPoints.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(snapshot.trendPoints[index].label);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Motifs d\'absence',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 26),
            ),
          ),
          const SizedBox(height: 16),
          CrfcCard(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 46,
                        sections: [
                          for (final share in snapshot.reasonShares)
                            PieChartSectionData(
                              color:
                                  Colors.blueGrey[(snapshot.reasonShares
                                              .indexOf(share) +
                                          2) *
                                      100],
                              value: share.percentage == 0
                                  ? 1
                                  : share.percentage,
                              title: '${share.percentage.round()}%',
                              radius: 58,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.reasonShares.map((share) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          '${share.percentage.round()}% ${share.reason.label}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Top retards (Fréquence)',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 26),
            ),
          ),
          const SizedBox(height: 16),
          ...snapshot.topLateEmployees.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CrfcCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${snapshot.topLateEmployees.indexOf(item) + 1}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.employee.fullName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Heure moy. ${item.averageArrivalTime}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.count}',
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(fontSize: 32),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ref
                      .read(appControllerProvider.notifier)
                      .generateExcelSummary(
                        start: _month,
                        end: DateTime(_month.year, _month.month + 1, 0),
                      );
                  if (context.mounted) {
                    showAppMessage(context, 'Synthèse Excel générée.');
                  }
                } catch (error) {
                  if (context.mounted) {
                    showAppMessage(context, error.toString(), isError: true);
                  }
                }
              },
              icon: const Icon(Icons.description_rounded),
              label: const Text('Générer la synthèse Excel'),
            ),
          ),
        ],
      ),
    );
  }
}
