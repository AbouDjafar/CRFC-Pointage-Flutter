import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets.dart';
import '../data/app_controller.dart';
import '../data/models.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jobTitleController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider).value;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = state.currentUser!;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _jobTitleController.text = user.jobTitle;

    return CrfcPageScaffold(
      title: 'Réglages du profil',
      subtitle: 'MON COMPTE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrfcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations personnelles',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jobTitleController,
                  decoration: const InputDecoration(labelText: 'Fonction'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(appControllerProvider.notifier)
                          .updateProfile(
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            jobTitle: _jobTitleController.text,
                          );
                      if (context.mounted) {
                        showAppMessage(context, 'Profil mis à jour.');
                      }
                    },
                    child: const Text('Enregistrer le profil'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CrfcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sécurité',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe actuel',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau mot de passe',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(appControllerProvider.notifier)
                            .changePassword(
                              currentPassword: _currentPasswordController.text,
                              newPassword: _newPasswordController.text,
                            );
                        if (context.mounted) {
                          showAppMessage(context, 'Mot de passe mis à jour.');
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
                    child: const Text('Mettre à jour le mot de passe'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CrfcCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: state.preferences.isDarkMode,
                  onChanged: (value) => ref
                      .read(appControllerProvider.notifier)
                      .toggleTheme(value),
                  title: const Text('Mode sombre'),
                  secondary: const Icon(Icons.brightness_6_rounded),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.group_add_rounded),
                  title: const Text('Gestion utilisateurs'),
                  onTap: user.role == UserRole.admin
                      ? () => context.go('/users')
                      : null,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Déconnexion',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () async {
                    await ref.read(appControllerProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  'CRFC Pointage v2.4.0',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  state.preferences.lastLoginAt == null
                      ? 'Première connexion'
                      : 'Dernière connexion : ${state.preferences.lastLoginAt}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
