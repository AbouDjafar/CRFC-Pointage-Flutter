import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/widgets.dart';
import '../data/app_controller.dart';

class ReportHistoryPage extends ConsumerStatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  ConsumerState<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends ConsumerState<ReportHistoryPage> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider).value;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final reports = state.reports.where((report) {
      if (_range == null) {
        return true;
      }
      return !report.date.isBefore(startOfDay(_range!.start)) &&
          !report.date.isAfter(startOfDay(_range!.end));
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return CrfcPageScaffold(
      title: 'Historique',
      subtitle: 'RAPPORTS PASSÉS',
      leading: IconButton(
        onPressed: () => context.go('/dashboard'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      trailing: IconButton(
        onPressed: () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            locale: const Locale('fr'),
          );
          if (range != null) {
            setState(() => _range = range);
          }
        },
        icon: const Icon(Icons.filter_alt_outlined),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_range != null) ...[
            CrfcCard(
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${formatShortDate(_range!.start)} - ${formatShortDate(_range!.end)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _range = null),
                    child: const Text('Effacer'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...reports.map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    context.go('/reports/daily?date=${report.dateIso}'),
                child: CrfcCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatLongDate(report.date),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              '${report.lateEntries.length} retard(s) • ${report.absenceEntries.length} absence(s) • ${report.visitorCount} visiteur(s)',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      ReportStatusBadge(report.status),
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
