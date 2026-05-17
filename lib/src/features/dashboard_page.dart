import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/widgets.dart';
import '../data/app_controller.dart';
import '../data/models.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final state = appState.value;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = state.currentUser!;
    final today = startOfDay(DateTime.now());
    final report = state.reportForDate(today);
    final analytics = controller.analyticsSnapshot(
      start: today.subtract(const Duration(days: 6)),
      end: today,
    );

    return CrfcPageScaffold(
      title: 'Tableau de Bord',
      subtitle: 'Bonjour, ${user.firstName}',
      trailing: CircleAvatar(radius: 22, child: Text(user.initials)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrfcCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 8,
                  backgroundColor: Color(0xFFD8873B),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report == null
                            ? 'Aucun rapport du jour'
                            : 'Rapport du ${formatLongDate(today)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        report == null
                            ? 'Initialisez la saisie quotidienne'
                            : 'Statut : ${report.status == ReportStatus.draft ? 'Brouillon' : 'Finalisé'} • ${report.lateEntries.length + report.absenceEntries.length} entrées',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final reportId = await controller.ensureReportForDate(
                      today,
                    );
                    if (context.mounted) {
                      context.go(
                        '/reports/daily?date=${civilDate(today)}&id=$reportId',
                      );
                    }
                  },
                  child: Text(report == null ? 'Démarrer' : 'Reprendre'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Center(child: CrfcSectionTitle(title: 'SYNTHÈSE DU JOUR')),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              CrfcStatCard(
                title: 'Retards',
                value: '${report?.lateEntries.length ?? 0}'.padLeft(2, '0'),
                subtitle: 'Depuis 08:15',
                icon: Icons.schedule_rounded,
              ),
              CrfcStatCard(
                title: 'Absences',
                value: '${report?.absenceEntries.length ?? 0}'.padLeft(2, '0'),
                subtitle: 'Motifs variés',
                icon: Icons.event_busy_rounded,
                iconColor: Colors.redAccent,
              ),
              CrfcStatCard(
                title: 'Visiteurs',
                value: '${report?.visitorCount ?? 0}',
                subtitle: 'Flux total',
                icon: Icons.groups_rounded,
              ),
              CrfcStatCard(
                title: 'Incidents',
                value:
                    '${(report?.lateEntries.length ?? 0) + (report?.absenceEntries.length ?? 0)}'
                        .padLeft(2, '0'),
                subtitle: 'Total journalier',
                icon: Icons.assessment_rounded,
                iconColor: Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 34),
          const Center(child: CrfcSectionTitle(title: 'ACTIONS RAPIDES')),
          const SizedBox(height: 18),
          CrfcActionTile(
            icon: Icons.playlist_add_check_circle_outlined,
            title: 'Nouveau Rapport',
            subtitle: 'Initialiser la saisie du jour',
            onTap: () async {
              final reportId = await controller.ensureReportForDate(today);
              if (context.mounted) {
                context.go(
                  '/reports/daily?date=${civilDate(today)}&id=$reportId',
                );
              }
            },
          ),
          const SizedBox(height: 16),
          CrfcActionTile(
            icon: Icons.history_rounded,
            title: 'Historique',
            subtitle: 'Consulter les rapports passés',
            onTap: () => context.go('/reports/history'),
          ),
          const SizedBox(height: 16),
          CrfcActionTile(
            icon: Icons.description_rounded,
            title: 'Exports & Analyses',
            subtitle: 'Générer PDF ou Excel',
            onTap: () => context.go('/exports'),
          ),
          const SizedBox(height: 16),
          CrfcActionTile(
            icon: Icons.analytics_outlined,
            title: 'Statistiques',
            subtitle: 'Visualiser les tendances',
            onTap: () => context.go('/analytics'),
          ),
          const SizedBox(height: 24),
          CrfcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Tendance (7 jours)',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/analytics'),
                      child: const Text('Voir plus'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: analytics.trendPoints.map((point) {
                      final height = (point.value * 22)
                          .clamp(6, 110)
                          .toDouble();
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 30,
                              height: height,
                              decoration: BoxDecoration(
                                color: const Color(0xFF52697A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(point.label),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
