import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import 'design_system.dart';

class CrfcPageScaffold extends StatelessWidget {
  const CrfcPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.child,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final Widget? bottom;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: CrfcColors.muted,
                            ),
                          ),
                        Text(title, style: theme.textTheme.headlineMedium),
                      ],
                    ),
                  ),
                  if (trailing case final Widget widget) widget,
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(padding: padding, child: child),
            ),
            if (bottom case final Widget widget) widget,
          ],
        ),
      ),
    );
  }
}

class CrfcCard extends StatelessWidget {
  const CrfcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: CrfcRadii.lg,
        border: Border.all(
          color: borderColor ?? Theme.of(context).dividerColor,
        ),
      ),
      child: child,
    );
  }
}

class CrfcSectionTitle extends StatelessWidget {
  const CrfcSectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: CrfcColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing case final Widget widget) widget,
      ],
    );
  }
}

class CrfcStatCard extends StatelessWidget {
  const CrfcStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.iconColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return CrfcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: CrfcColors.muted),
                ),
              ),
              Icon(icon, color: iconColor ?? CrfcColors.accentBlue),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class CrfcActionTile extends StatelessWidget {
  const CrfcActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: CrfcRadii.lg,
      onTap: onTap,
      child: CrfcCard(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: CrfcRadii.lg,
              ),
              child: Icon(icon, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 30,
              color: CrfcColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge(this.status, {super.key});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final isDraft = status == ReportStatus.draft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDraft ? const Color(0xFFE5F2E4) : const Color(0xFFFFF1DF),
        borderRadius: CrfcRadii.full,
      ),
      child: Text(
        isDraft ? 'Brouillon' : 'Finalisé',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: isDraft ? CrfcColors.success : CrfcColors.primary,
        ),
      ),
    );
  }
}

class CrfcShellScaffold extends StatelessWidget {
  const CrfcShellScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    final currentIndex = switch (location) {
      '/employees' => 1,
      '/profile' => 2,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/employees');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Personnel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Réglages',
          ),
        ],
      ),
    );
  }
}

void showAppMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? CrfcColors.error : CrfcColors.success,
    ),
  );
}
