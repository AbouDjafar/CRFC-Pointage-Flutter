import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets.dart';
import '../core/design_system.dart';
import '../data/app_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _identifierController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'Admin@2026');
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(appControllerProvider.notifier)
          .login(
            identifier: _identifierController.text,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      context.go('/dashboard');
    } catch (error) {
      if (mounted) {
        showAppMessage(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        color: const Color(0xFFF1ECE3),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),
                Container(
                  width: 160,
                  height: 160,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: CrfcColors.accentBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset(
                    'design-screenshots/Login.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.question_mark_rounded,
                      color: Colors.white,
                      size: 72,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'CRFC Pointage',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: CrfcColors.accentBlue,
                    fontSize: 44,
                  ),
                ),
                Text(
                  'Système de Gestion des Présences',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: CrfcColors.muted,
                  ),
                ),
                const SizedBox(height: 58),
                CrfcCard(
                  borderColor: const Color(0xFFBFD8BC),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Connexion',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Veuillez entrer vos identifiants pour accéder au tableau de bord.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'IDENTIFIANT OU EMAIL',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: CrfcColors.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          hintText: 'ex: j.dupont',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'MOT DE PASSE',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: CrfcColors.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Mot de passe oublié ?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: CrfcColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            _submitting ? 'Connexion...' : 'Se connecter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Civic Functionalism v2.4',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: CrfcColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: CrfcColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Accès sécurisé réservé au personnel du CRFC',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: CrfcColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
