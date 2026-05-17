import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets.dart';
import '../data/app_controller.dart';

class EmployeeDirectoryPage extends ConsumerStatefulWidget {
  const EmployeeDirectoryPage({super.key});

  @override
  ConsumerState<EmployeeDirectoryPage> createState() =>
      _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState extends ConsumerState<EmployeeDirectoryPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider).value;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final filtered = state.employees.where((employee) {
      if (_query.isEmpty) {
        return true;
      }
      return employee.fullName.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return CrfcPageScaffold(
      title: 'Annuaire du Personnel',
      subtitle: 'EMPLOYÉS',
      trailing: PopupMenuButton<String>(
        onSelected: (value) => context.go(value),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: '/recurring-absences',
            child: Text('Absences récurrentes'),
          ),
          PopupMenuItem(value: '/users', child: Text('Gestion utilisateurs')),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Rechercher un employé',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final message = await ref
                        .read(appControllerProvider.notifier)
                        .importEmployees();
                    if (context.mounted && message != null) {
                      showAppMessage(context, message);
                    }
                  },
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Importer Excel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...filtered.map(
            (employee) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CrfcCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.fullName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            employee.needsReview
                                ? 'Vérification requise'
                                : 'Import: ${employee.importSource}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    if (employee.needsReview)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Needs review'),
                      ),
                    const SizedBox(width: 12),
                    Switch(
                      value: employee.isActive,
                      onChanged: (_) => ref
                          .read(appControllerProvider.notifier)
                          .toggleEmployeeActive(employee.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
