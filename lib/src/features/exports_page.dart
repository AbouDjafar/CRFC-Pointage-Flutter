import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets.dart';
import '../data/app_controller.dart';
import '../data/models.dart';

class ExportsPage extends ConsumerStatefulWidget {
  const ExportsPage({super.key});

  @override
  ConsumerState<ExportsPage> createState() => _ExportsPageState();
}

class _ExportsPageState extends ConsumerState<ExportsPage> {
  ManagedFileType _filter = ManagedFileType.pdf;

  Future<void> _renameFile(BuildContext context, ManagedFile file) async {
    final controller = TextEditingController(text: file.name.split('.').first);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer'),
        content: TextField(controller: controller),
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
          .renameManagedFile(file.id, controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider).value;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final files =
        state.managedFiles.where((file) => file.type == _filter).toList()
          ..sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));

    return CrfcPageScaffold(
      title: 'Archives & Exports',
      subtitle: 'FICHIERS',
      leading: IconButton(
        onPressed: () => context.go('/dashboard'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text('Rapports PDF'),
                selected: _filter == ManagedFileType.pdf,
                onSelected: (_) =>
                    setState(() => _filter = ManagedFileType.pdf),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Synthèses Excel'),
                selected: _filter == ManagedFileType.excel,
                onSelected: (_) =>
                    setState(() => _filter = ManagedFileType.excel),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...files.map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CrfcCard(
                child: Row(
                  children: [
                    Icon(
                      file.type == ManagedFileType.pdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.grid_on_rounded,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            file.createdAtIso.split('T').first,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(appControllerProvider.notifier)
                          .openManagedFile(file.id),
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(appControllerProvider.notifier)
                          .shareManagedFile(file.id),
                      icon: const Icon(Icons.share_outlined),
                    ),
                    IconButton(
                      onPressed: () => _renameFile(context, file),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(appControllerProvider.notifier)
                          .deleteManagedFile(file.id),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _filter == ManagedFileType.pdf
                      ? () async {
                          final report = state.reports.firstWhere(
                            (item) => item.status == ReportStatus.finalized,
                            orElse: () => state.reports.first,
                          );
                          await ref
                              .read(appControllerProvider.notifier)
                              .generatePdfForReport(report.id);
                        }
                      : null,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Nouveau PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _filter == ManagedFileType.excel
                      ? () async {
                          final now = DateTime.now();
                          await ref
                              .read(appControllerProvider.notifier)
                              .generateExcelSummary(
                                start: DateTime(now.year, now.month, 1),
                                end: DateTime(now.year, now.month + 1, 0),
                              );
                        }
                      : null,
                  icon: const Icon(Icons.grid_on_rounded),
                  label: const Text('Synthèse Excel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
