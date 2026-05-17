import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/widgets.dart';
import '../data/app_controller.dart';
import '../data/models.dart';

class DailyReportPage extends ConsumerStatefulWidget {
  const DailyReportPage({super.key, this.dateIso});

  final String? dateIso;

  @override
  ConsumerState<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends ConsumerState<DailyReportPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.dateIso == null
        ? startOfDay(DateTime.now())
        : parseCivilDate(widget.dateIso!);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(appControllerProvider.notifier)
          .ensureReportForDate(_selectedDate);
    });
  }

  Future<void> _addLate(
    BuildContext context,
    CrfcState state,
    DailyReport report,
  ) async {
    final availableEmployees = state.activeEmployees
        .where(
          (employee) => !report.lateEntries.any(
            (entry) => entry.employeeId == employee.id,
          ),
        )
        .where(
          (employee) => !report.absenceEntries.any(
            (entry) => entry.employeeId == employee.id,
          ),
        )
        .toList();
    if (availableEmployees.isEmpty) {
      showAppMessage(context, 'Aucun employé disponible.', isError: true);
      return;
    }
    String employeeId = availableEmployees.first.id;
    final arrivalController = TextEditingController(text: '08:30');
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un retard'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: employeeId,
                items: availableEmployees
                    .map(
                      (employee) => DropdownMenuItem(
                        value: employee.id,
                        child: Text(employee.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => employeeId = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: arrivalController,
                decoration: const InputDecoration(
                  labelText: 'Heure d’arrivée (HH:mm)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref
            .read(appControllerProvider.notifier)
            .addLateEntry(
              reportId: report.id,
              employeeId: employeeId,
              arrivalTime: arrivalController.text,
              note: noteController.text,
            );
      } catch (error) {
        if (context.mounted) {
          showAppMessage(context, error.toString(), isError: true);
        }
      }
    }
  }

  Future<void> _addAbsence(
    BuildContext context,
    CrfcState state,
    DailyReport report,
  ) async {
    final availableEmployees = state.activeEmployees
        .where(
          (employee) => !report.lateEntries.any(
            (entry) => entry.employeeId == employee.id,
          ),
        )
        .where(
          (employee) => !report.absenceEntries.any(
            (entry) => entry.employeeId == employee.id,
          ),
        )
        .toList();
    if (availableEmployees.isEmpty) {
      showAppMessage(context, 'Aucun employé disponible.', isError: true);
      return;
    }
    String employeeId = availableEmployees.first.id;
    String reasonId = state.absenceReasons.first.id;
    final commentController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une absence'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: employeeId,
                items: availableEmployees
                    .map(
                      (employee) => DropdownMenuItem(
                        value: employee.id,
                        child: Text(employee.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => employeeId = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: reasonId,
                items: state.absenceReasons
                    .map(
                      (reason) => DropdownMenuItem(
                        value: reason.id,
                        child: Text(reason.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => reasonId = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Commentaire'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref
            .read(appControllerProvider.notifier)
            .addAbsenceEntry(
              reportId: report.id,
              employeeId: employeeId,
              reasonId: reasonId,
              comment: commentController.text,
            );
      } catch (error) {
        if (context.mounted) {
          showAppMessage(context, error.toString(), isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final state = appState.value;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final report = state.reportForDate(_selectedDate);
    if (report == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final editable = report.status == ReportStatus.draft;

    return CrfcPageScaffold(
      title: formatLongDate(_selectedDate),
      subtitle: 'RAPPORT JOURNALIER',
      leading: IconButton(
        onPressed: () => context.go('/dashboard'),
        icon: const Icon(Icons.chevron_left_rounded, size: 34),
      ),
      trailing: IconButton(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            locale: const Locale('fr'),
          );
          if (picked != null) {
            setState(() => _selectedDate = startOfDay(picked));
            await ref
                .read(appControllerProvider.notifier)
                .ensureReportForDate(_selectedDate);
          }
        },
        icon: const Icon(Icons.chevron_right_rounded, size: 34),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: editable
                    ? () async {
                        try {
                          await ref
                              .read(appControllerProvider.notifier)
                              .finalizeReport(report.id);
                          if (context.mounted) {
                            showAppMessage(context, 'Rapport finalisé.');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            showAppMessage(
                              context,
                              error.toString(),
                              isError: true,
                            );
                          }
                        }
                      }
                    : () async {
                        try {
                          await ref
                              .read(appControllerProvider.notifier)
                              .reopenReport(report.id);
                          if (context.mounted) {
                            showAppMessage(context, 'Rapport rouvert.');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            showAppMessage(
                              context,
                              error.toString(),
                              isError: true,
                            );
                          }
                        }
                      },
                icon: Icon(
                  editable ? Icons.lock_rounded : Icons.lock_open_rounded,
                ),
                label: Text(
                  editable ? 'Finaliser le rapport' : 'Rouvrir le rapport',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              editable
                  ? 'La finalisation verrouille les données et prépare l’export PDF.'
                  : 'Le rapport est verrouillé tant qu’il n’est pas rouvert.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrfcCard(
            borderColor: editable
                ? Colors.blue.shade700
                : Theme.of(context).dividerColor,
            child: Row(
              children: [
                Icon(
                  editable
                      ? Icons.edit_note_rounded
                      : Icons.check_circle_rounded,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Text(
                  'Statut : ${editable ? 'Brouillon' : 'Finalisé'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CrfcCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visiteurs',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Compte total de la journée',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: editable
                      ? () => ref
                            .read(appControllerProvider.notifier)
                            .changeVisitorCount(reportId: report.id, delta: -1)
                      : null,
                  icon: const Icon(Icons.remove_rounded, size: 34),
                ),
                Text(
                  '${report.visitorCount}',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                IconButton(
                  onPressed: editable
                      ? () => ref
                            .read(appControllerProvider.notifier)
                            .changeVisitorCount(reportId: report.id, delta: 1)
                      : null,
                  icon: const Icon(Icons.add_rounded, size: 34),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          CrfcSectionTitle(
            title: 'RETARDS (08:15)',
            trailing: TextButton.icon(
              onPressed: editable
                  ? () => _addLate(context, state, report)
                  : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter'),
            ),
          ),
          const SizedBox(height: 14),
          ...report.lateEntries.map((entry) {
            final employee = state.employeeById(entry.employeeId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CrfcCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee?.fullName ?? 'Employé',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Arrivée à ${entry.arrivalTime} (+${entry.minutesLate} min)',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: editable
                          ? () => ref
                                .read(appControllerProvider.notifier)
                                .removeLateEntry(
                                  reportId: report.id,
                                  entryId: entry.id,
                                )
                          : null,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          CrfcSectionTitle(
            title: 'ABSENCES',
            trailing: TextButton.icon(
              onPressed: editable
                  ? () => _addAbsence(context, state, report)
                  : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter'),
            ),
          ),
          const SizedBox(height: 14),
          ...report.absenceEntries.map((entry) {
            final employee = state.employeeById(entry.employeeId);
            final reason = state.reasonById(entry.reasonId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CrfcCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee?.fullName ?? 'Employé',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            entry.comment.isEmpty
                                ? (reason?.label ?? 'Motif')
                                : '${reason?.label ?? 'Motif'} (${entry.comment})',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: editable
                          ? () => ref
                                .read(appControllerProvider.notifier)
                                .removeAbsenceEntry(
                                  reportId: report.id,
                                  entryId: entry.id,
                                )
                          : null,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
