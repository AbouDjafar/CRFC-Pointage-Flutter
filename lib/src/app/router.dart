import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets.dart';
import '../data/app_controller.dart';
import '../features/analytics_page.dart';
import '../features/dashboard_page.dart';
import '../features/daily_report_page.dart';
import '../features/employee_directory_page.dart';
import '../features/exports_page.dart';
import '../features/login_page.dart';
import '../features/profile_settings_page.dart';
import '../features/recurring_absences_page.dart';
import '../features/report_history_page.dart';
import '../features/splash_page.dart';
import '../features/user_management_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(appControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }
      final isLoggedIn = authState.value?.currentUser != null;
      final location = state.matchedLocation;
      if (!isLoggedIn && location != '/login' && location != '/splash') {
        return '/login';
      }
      if (isLoggedIn && (location == '/login' || location == '/splash')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) =>
            CrfcShellScaffold(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/employees',
            builder: (context, state) => const EmployeeDirectoryPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileSettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/reports/daily',
        builder: (context, state) =>
            DailyReportPage(dateIso: state.uri.queryParameters['date']),
      ),
      GoRoute(
        path: '/reports/history',
        builder: (context, state) => const ReportHistoryPage(),
      ),
      GoRoute(
        path: '/recurring-absences',
        builder: (context, state) => const RecurringAbsencesPage(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/exports',
        builder: (context, state) => const ExportsPage(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UserManagementPage(),
      ),
    ],
  );
});
