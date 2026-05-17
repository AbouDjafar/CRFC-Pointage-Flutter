import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets.dart';
import '../data/app_controller.dart';

class RecurringAbsencesPage extends ConsumerWidget {
  const RecurringAbsencesPage({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    String? recurringId,
  }) async {
    final state = ref.read(appControllerProvider).value;
    if (state == null || state.activeEmployees.isEmpty) {
      return;
    }
    final existing = recurringId == null
        ? null
        : state.recurringAbsences.firstWhere((item) => item.id == recurringId);
    String employeeId = existing?.employeeId ?? state.activeEmployees.first.id;
    String reasonId = existing?.reasonId ?? state.absenceReasons.first.id;
    final commentController = TextEditingController(
      text: existing?.comment ?? '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existing == null ? 'Nouvelle absence récurrente' : 'Modifier',
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: employeeId,
                items: state.activeEmployees.map((employee) {
                  return DropdownMenuItem(
                    value: employee.id,
                    child: Text(employee.fullName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => employeeId = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: reasonId,
                items: state.absenceReasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason.id,
                    child: Text(reason.label),
                  );
                }).toList(),
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(appControllerProvider.notifier)
          .upsertRecurringAbsence(
            recurringId: recurringId,
            employeeId: employeeId,
            reasonId: reasonId,
            comment: commentController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider).value;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return CrfcPageScaffold(
      title: 'Absences récurrentes',
      subtitle: 'CONFIGURATION',
      leading: IconButton(
        onPressed: () => context.go('/employees'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      trailing: IconButton(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
      ),
      child: Column(
        children: state.recurringAbsences.map((item) {
          final employee = state.employeeById(item.employeeId);
          final reason = state.reasonById(item.reasonId);
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
                          item.comment.isEmpty
                              ? (reason?.label ?? 'Motif')
                              : '${reason?.label ?? 'Motif'} • ${item.comment}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        _openEditor(context, ref, recurringId: item.id),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    onPressed: () => ref
                        .read(appControllerProvider.notifier)
                        .deleteRecurringAbsence(item.id),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
