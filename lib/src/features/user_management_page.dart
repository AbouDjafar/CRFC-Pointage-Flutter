import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets.dart';
import '../data/app_controller.dart';
import '../data/models.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    AppUser? user,
  }) async {
    final isEditing = user != null;
    final firstNameController = TextEditingController(
      text: user?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: user?.lastName ?? '',
    );
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    final jobTitleController = TextEditingController(
      text: user?.jobTitle ?? '',
    );
    UserRole role = user?.role ?? UserRole.agent;
    bool isActive = user?.isActive ?? true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier utilisateur' : 'Nouvel utilisateur'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                if (!isEditing) ...[
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: jobTitleController,
                  decoration: const InputDecoration(labelText: 'Fonction'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  items: UserRole.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => role = value!),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                  title: const Text('Compte actif'),
                ),
              ],
            ),
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
      if (isEditing) {
        await ref
            .read(appControllerProvider.notifier)
            .updateUser(
              userId: user.id,
              firstName: firstNameController.text,
              lastName: lastNameController.text,
              email: emailController.text,
              jobTitle: jobTitleController.text,
              role: role,
              isActive: isActive,
            );
      } else {
        await ref
            .read(appControllerProvider.notifier)
            .createUser(
              firstName: firstNameController.text,
              lastName: lastNameController.text,
              email: emailController.text,
              password: passwordController.text,
              jobTitle: jobTitleController.text,
              role: role,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider).value;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.currentUser?.role != UserRole.admin) {
      return CrfcPageScaffold(
        title: 'Gestion des utilisateurs',
        subtitle: 'ADMIN',
        child: const Center(child: Text('Accès réservé à l’administrateur.')),
      );
    }

    return CrfcPageScaffold(
      title: 'Gestion des utilisateurs',
      subtitle: 'ADMIN',
      leading: IconButton(
        onPressed: () => context.go('/employees'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      trailing: IconButton(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
      ),
      child: Column(
        children: state.users.map((user) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CrfcCard(
              child: Row(
                children: [
                  CircleAvatar(child: Text(user.initials)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${user.email} • ${user.role.name.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: user.isActive,
                    onChanged: (_) => ref
                        .read(appControllerProvider.notifier)
                        .toggleUserActive(user.id),
                  ),
                  IconButton(
                    onPressed: () => _openEditor(context, ref, user: user),
                    icon: const Icon(Icons.edit_rounded),
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
