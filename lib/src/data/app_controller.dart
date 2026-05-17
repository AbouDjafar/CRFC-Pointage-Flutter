import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/formatters.dart';
import 'app_database.dart';
import 'models.dart';
import 'report_rules.dart';
import 'services.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final localStateStoreProvider = Provider<LocalStateStore>((ref) {
  return DriftLocalStateStore(ref.watch(appDatabaseProvider));
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SecureSessionStorage();
});

final employeeImportServiceProvider = Provider<EmployeeImportService>((ref) {
  return EmployeeImportService();
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

final appControllerProvider = AsyncNotifierProvider<AppController, CrfcState>(
  AppController.new,
);

class AppController extends AsyncNotifier<CrfcState> {
  static const _defaultReasonLabel = 'Absence injustifiée';
  final Uuid _uuid = const Uuid();

  LocalStateStore get _store => ref.read(localStateStoreProvider);
  SessionStorage get _sessionStorage => ref.read(sessionStorageProvider);
  EmployeeImportService get _importService =>
      ref.read(employeeImportServiceProvider);
  ExportService get _exportService => ref.read(exportServiceProvider);

  @override
  Future<CrfcState> build() async {
    final stored = await _store.load();
    final baseState = stored ?? _seedState();
    if (stored == null) {
      await _store.save(baseState);
    }
    final sessionUserId = await _sessionStorage.readCurrentUserId();
    final sessionUser = baseState.users.firstWhereOrNull(
      (user) => user.id == sessionUserId && user.isActive,
    );
    if (sessionUser == null && sessionUserId != null) {
      await _sessionStorage.clear();
    }
    return baseState.copyWith(currentUserId: sessionUser?.id);
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final current = state.requireValue;
    final normalized = normalizeText(identifier);
    final user = current.users.firstWhereOrNull((candidate) {
      return normalizeText(candidate.email) == normalized ||
          normalizeText(candidate.shortLogin) == normalized;
    });
    if (user == null || !user.isActive) {
      throw StateError('Identifiants invalides ou compte inactif.');
    }
    if (user.passwordHash != _hashPassword(password)) {
      throw StateError('Mot de passe incorrect.');
    }
    await _sessionStorage.writeCurrentUserId(user.id);
    await _saveState(
      current.copyWith(
        currentUserId: user.id,
        preferences: current.preferences.copyWith(
          lastLoginAtIso: DateTime.now().toIso8601String(),
        ),
      ),
    );
  }

  Future<void> logout() async {
    final current = state.requireValue;
    await _sessionStorage.clear();
    state = AsyncData(current.copyWith(currentUserId: null));
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    final current = state.requireValue;
    await _saveState(
      current.copyWith(
        preferences: current.preferences.copyWith(isDarkMode: isDarkMode),
      ),
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String jobTitle,
  }) async {
    final current = state.requireValue;
    final user = _requireCurrentUser(current);
    final updatedUsers = current.users
        .map(
          (candidate) => candidate.id == user.id
              ? candidate.copyWith(
                  firstName: firstName.trim(),
                  lastName: lastName.trim(),
                  jobTitle: jobTitle.trim(),
                )
              : candidate,
        )
        .toList();
    await _saveState(current.copyWith(users: updatedUsers));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = state.requireValue;
    final user = _requireCurrentUser(current);
    if (user.passwordHash != _hashPassword(currentPassword)) {
      throw StateError('Le mot de passe actuel est incorrect.');
    }
    if (newPassword.trim().length < 8) {
      throw StateError(
        'Le nouveau mot de passe doit contenir au moins 8 caractères.',
      );
    }
    final updatedUsers = current.users
        .map(
          (candidate) => candidate.id == user.id
              ? candidate.copyWith(passwordHash: _hashPassword(newPassword))
              : candidate,
        )
        .toList();
    await _saveState(current.copyWith(users: updatedUsers));
  }

  Future<String> ensureReportForDate(DateTime date) async {
    final current = state.requireValue;
    final existing = current.reportForDate(date);
    if (existing != null) {
      return existing.id;
    }
    final user = _requireCurrentUser(current);
    final defaultReason = current.absenceReasons.firstWhere(
      (reason) => reason.label == _defaultReasonLabel,
    );
    final report = createDraftReport(
      state: current,
      author: user,
      date: date,
      defaultReasonId: defaultReason.id,
      createId: _uuid.v4,
    );
    await _saveState(current.copyWith(reports: [...current.reports, report]));
    return report.id;
  }

  Future<void> changeVisitorCount({
    required String reportId,
    required int delta,
  }) async {
    final report = _requireReport(reportId);
    ensureReportEditable(report);
    final updated = report.copyWith(
      visitorCount: (report.visitorCount + delta).clamp(0, 9999),
      updatedAtIso: DateTime.now().toIso8601String(),
    );
    await _replaceReport(updated);
  }

  Future<void> addLateEntry({
    required String reportId,
    required String employeeId,
    required String arrivalTime,
    String note = '',
  }) async {
    final current = state.requireValue;
    final report = _requireReport(reportId);
    ensureReportEditable(report);
    ensureEmployeeEligible(
      state: current,
      report: report,
      employeeId: employeeId,
    );
    final entry = LateEntry(
      id: _uuid.v4(),
      employeeId: employeeId,
      arrivalTime: arrivalTime,
      minutesLate: computeLateMinutes(arrivalTime),
      note: note.trim(),
    );
    await _replaceReport(
      report.copyWith(
        lateEntries: [...report.lateEntries, entry],
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> removeLateEntry({
    required String reportId,
    required String entryId,
  }) async {
    final report = _requireReport(reportId);
    ensureReportEditable(report);
    await _replaceReport(
      report.copyWith(
        lateEntries: report.lateEntries
            .where((entry) => entry.id != entryId)
            .toList(),
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> addAbsenceEntry({
    required String reportId,
    required String employeeId,
    required String reasonId,
    String comment = '',
  }) async {
    final current = state.requireValue;
    final report = _requireReport(reportId);
    ensureReportEditable(report);
    ensureEmployeeEligible(
      state: current,
      report: report,
      employeeId: employeeId,
    );
    final entry = AbsenceEntry(
      id: _uuid.v4(),
      employeeId: employeeId,
      reasonId: reasonId,
      comment: comment.trim(),
    );
    await _replaceReport(
      report.copyWith(
        absenceEntries: [...report.absenceEntries, entry],
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> removeAbsenceEntry({
    required String reportId,
    required String entryId,
  }) async {
    final report = _requireReport(reportId);
    ensureReportEditable(report);
    await _replaceReport(
      report.copyWith(
        absenceEntries: report.absenceEntries
            .where((entry) => entry.id != entryId)
            .toList(),
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> finalizeReport(String reportId) async {
    final report = _requireReport(reportId);
    await _replaceReport(
      report.copyWith(
        status: ReportStatus.finalized,
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> reopenReport(String reportId) async {
    final current = state.requireValue;
    final user = _requireCurrentUser(current);
    if (user.role != UserRole.admin) {
      throw StateError('Seul un administrateur peut rouvrir un rapport.');
    }
    final report = _requireReport(reportId);
    await _replaceReport(
      report.copyWith(
        status: ReportStatus.draft,
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> deleteReport(String reportId) async {
    final current = state.requireValue;
    final user = _requireCurrentUser(current);
    if (user.role != UserRole.admin) {
      throw StateError('Suppression réservée à l’administrateur.');
    }
    await _saveState(
      current.copyWith(
        reports: current.reports
            .where((report) => report.id != reportId)
            .toList(),
      ),
    );
  }

  Future<String?> importEmployees() async {
    final current = state.requireValue;
    final result = await _importService.pickAndImport(current.employees);
    if (result == null) {
      return null;
    }
    await _saveState(current.copyWith(employees: result.employees));
    return '${result.addedCount} ajout(s), ${result.updatedCount} mise(s) à jour';
  }

  Future<void> toggleEmployeeActive(String employeeId) async {
    final current = state.requireValue;
    final updated = current.employees
        .map(
          (employee) => employee.id == employeeId
              ? employee.copyWith(isActive: !employee.isActive)
              : employee,
        )
        .toList();
    await _saveState(current.copyWith(employees: updated));
  }

  Future<void> upsertRecurringAbsence({
    String? recurringId,
    required String employeeId,
    required String reasonId,
    required String comment,
  }) async {
    final current = state.requireValue;
    final filtered = current.recurringAbsences
        .where(
          (item) => item.employeeId != employeeId || item.id == recurringId,
        )
        .toList();
    final updatedItem = RecurringAbsence(
      id: recurringId ?? _uuid.v4(),
      employeeId: employeeId,
      reasonId: reasonId,
      comment: comment.trim(),
    );
    final index = filtered.indexWhere((item) => item.id == updatedItem.id);
    if (index == -1) {
      filtered.add(updatedItem);
    } else {
      filtered[index] = updatedItem;
    }
    await _saveState(current.copyWith(recurringAbsences: filtered));
  }

  Future<void> deleteRecurringAbsence(String recurringId) async {
    final current = state.requireValue;
    await _saveState(
      current.copyWith(
        recurringAbsences: current.recurringAbsences
            .where((item) => item.id != recurringId)
            .toList(),
      ),
    );
  }

  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String jobTitle,
    required UserRole role,
  }) async {
    final current = state.requireValue;
    final actor = _requireCurrentUser(current);
    if (actor.role != UserRole.admin) {
      throw StateError('Création d’utilisateur réservée à l’administrateur.');
    }
    if (current.users.any(
      (user) => normalizeText(user.email) == normalizeText(email),
    )) {
      throw StateError('Cet email existe déjà.');
    }
    final user = AppUser(
      id: _uuid.v4(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      passwordHash: _hashPassword(password),
      jobTitle: jobTitle.trim(),
      role: role,
      isActive: true,
      createdAtIso: DateTime.now().toIso8601String(),
      createdBy: actor.id,
    );
    await _saveState(current.copyWith(users: [...current.users, user]));
  }

  Future<void> updateUser({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String jobTitle,
    required UserRole role,
    required bool isActive,
  }) async {
    final current = state.requireValue;
    final actor = _requireCurrentUser(current);
    if (actor.role != UserRole.admin) {
      throw StateError('Modification réservée à l’administrateur.');
    }
    final updatedUsers = current.users.map((user) {
      if (user.id != userId) {
        return user;
      }
      return user.copyWith(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        jobTitle: jobTitle.trim(),
        role: role,
        isActive: isActive,
      );
    }).toList();
    await _saveState(current.copyWith(users: updatedUsers));
  }

  Future<void> toggleUserActive(String userId) async {
    final current = state.requireValue;
    final actor = _requireCurrentUser(current);
    if (actor.role != UserRole.admin) {
      throw StateError('Action réservée à l’administrateur.');
    }
    final updatedUsers = current.users.map((user) {
      if (user.id != userId) {
        return user;
      }
      return user.copyWith(isActive: !user.isActive);
    }).toList();
    await _saveState(current.copyWith(users: updatedUsers));
  }

  Future<void> generatePdfForReport(String reportId) async {
    final current = state.requireValue;
    final report = _requireReport(reportId);
    final author =
        current.userById(report.createdBy) ?? _requireCurrentUser(current);
    final file = await _exportService.generatePdf(
      report: report,
      state: current,
      author: author,
    );
    final refreshedReport = report.copyWith(pdfPath: file.path);
    final updatedReports = current.reports
        .map(
          (candidate) =>
              candidate.id == report.id ? refreshedReport : candidate,
        )
        .toList();
    await _saveState(
      current.copyWith(
        reports: updatedReports,
        managedFiles: [
          file,
          ...current.managedFiles.where((item) => item.id != file.id),
        ],
      ),
    );
  }

  Future<void> generateExcelSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    final current = state.requireValue;
    if (!current.reports.any((report) {
      return !report.date.isBefore(startOfDay(start)) &&
          !report.date.isAfter(startOfDay(end));
    })) {
      throw StateError('Aucun rapport dans cette période.');
    }
    final file = await _exportService.generateExcel(
      state: current,
      start: start,
      end: end,
    );
    await _saveState(
      current.copyWith(
        managedFiles: [
          file,
          ...current.managedFiles.where((item) => item.id != file.id),
        ],
      ),
    );
  }

  Future<void> renameManagedFile(String fileId, String newName) async {
    final current = state.requireValue;
    final target = current.managedFiles.firstWhere((file) => file.id == fileId);
    final renamed = await _exportService.renameManagedFile(target, newName);
    await _saveState(
      current.copyWith(
        managedFiles: current.managedFiles
            .map((file) => file.id == fileId ? renamed : file)
            .toList(),
      ),
    );
  }

  Future<void> deleteManagedFile(String fileId) async {
    final current = state.requireValue;
    final target = current.managedFiles.firstWhere((file) => file.id == fileId);
    await _exportService.deleteManagedFile(target);
    await _saveState(
      current.copyWith(
        managedFiles: current.managedFiles
            .where((file) => file.id != fileId)
            .toList(),
      ),
    );
  }

  Future<void> openManagedFile(String fileId) async {
    final current = state.requireValue;
    final target = current.managedFiles.firstWhere((file) => file.id == fileId);
    await _exportService.openManagedFile(target);
  }

  Future<void> shareManagedFile(String fileId) async {
    final current = state.requireValue;
    final target = current.managedFiles.firstWhere((file) => file.id == fileId);
    await _exportService.shareManagedFile(target);
  }

  AnalyticsSnapshot analyticsSnapshot({DateTime? start, DateTime? end}) {
    final current = state.requireValue;
    final startDate = startOfDay(
      start ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
    );
    final endDate = startOfDay(
      end ?? DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
    );
    final reports = current.reports.where((report) {
      return !report.date.isBefore(startDate) && !report.date.isAfter(endDate);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final totalLate = reports.fold<int>(
      0,
      (sum, report) => sum + report.lateEntries.length,
    );
    final totalAbsence = reports.fold<int>(
      0,
      (sum, report) => sum + report.absenceEntries.length,
    );
    final totalVisitors = reports.fold<int>(
      0,
      (sum, report) => sum + report.visitorCount,
    );
    final lateMinutes = reports
        .expand((report) => report.lateEntries)
        .map((entry) => entry.minutesLate)
        .toList();
    final averageLateMinutes = lateMinutes.isEmpty
        ? 0
        : lateMinutes.reduce((a, b) => a + b) / lateMinutes.length;

    final absenceReasonCounter = <String, int>{};
    for (final entry in reports.expand((report) => report.absenceEntries)) {
      absenceReasonCounter.update(
        entry.reasonId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final reasonShares = absenceReasonCounter.entries.map((entry) {
      final reason = current.reasonById(entry.key)!;
      final percentage = totalAbsence == 0
          ? 0.0
          : ((entry.value / totalAbsence) * 100).toDouble();
      return ReasonShare(
        reason: reason,
        count: entry.value,
        percentage: percentage,
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));

    final lateByEmployee = <String, List<LateEntry>>{};
    for (final entry in reports.expand((report) => report.lateEntries)) {
      lateByEmployee.putIfAbsent(entry.employeeId, () => []).add(entry);
    }
    final topLateEmployees = lateByEmployee.entries.map((entry) {
      final employee = current.employeeById(entry.key)!;
      final averageArrival = _averageArrivalTime(entry.value);
      return RankedEmployee(
        employee: employee,
        count: entry.value.length,
        averageArrivalTime: averageArrival,
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));

    final trendPoints = reports.map((report) {
      return TrendPoint(
        label: 'S${report.date.day}',
        value: (report.lateEntries.length + report.absenceEntries.length)
            .toDouble(),
      );
    }).toList();

    return AnalyticsSnapshot(
      reportCount: reports.length,
      totalLate: totalLate,
      totalAbsence: totalAbsence,
      totalVisitors: totalVisitors,
      totalIncidents: totalLate + totalAbsence,
      averageLateMinutes: averageLateMinutes.toDouble(),
      reasonShares: reasonShares.take(4).toList(),
      topLateEmployees: topLateEmployees.take(5).toList(),
      trendPoints: trendPoints,
    );
  }

  Future<void> _replaceReport(DailyReport report) async {
    final current = state.requireValue;
    final updatedReports =
        current.reports
            .map((candidate) => candidate.id == report.id ? report : candidate)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    await _saveState(current.copyWith(reports: updatedReports));
  }

  Future<void> _saveState(CrfcState updatedState) async {
    state = AsyncData(updatedState);
    await _store.save(updatedState.copyWith(currentUserId: null));
  }

  AppUser _requireCurrentUser(CrfcState current) {
    final user = current.currentUser;
    if (user == null) {
      throw StateError('Aucune session active.');
    }
    return user;
  }

  DailyReport _requireReport(String reportId) {
    final current = state.requireValue;
    final report = current.reports.firstWhereOrNull(
      (candidate) => candidate.id == reportId,
    );
    if (report == null) {
      throw StateError('Rapport introuvable.');
    }
    return report;
  }

  CrfcState _seedState() {
    final adminId = _uuid.v4();
    final now = DateTime.now();
    final absenceReasons = [
      'Maladie',
      'Congé',
      'Mission',
      'Permission',
      'Formation',
      'Déplacement',
      'Absence injustifiée',
      'Autre',
    ].map((label) => AbsenceReason(id: _uuid.v4(), label: label)).toList();

    final employees =
        [
          'Jean-Baptiste L.',
          'Marie-Claire D.',
          'Thomas Muller',
          'Sarah Benali',
          'Marc Dupont',
          'Amina Tchoumba',
          'Paul Nkomo',
          'Larissa Ndzi',
        ].map((fullName) {
          final parts = splitHumanName(fullName);
          return Employee(
            id: _uuid.v4(),
            fullName: fullName,
            firstName: parts.firstName,
            lastName: parts.lastName,
            isActive: true,
            needsReview: parts.needsReview,
            importSource: 'seed',
            importedAtIso: now.toIso8601String(),
          );
        }).toList();

    final recurringAbsenceReason = absenceReasons.firstWhere(
      (item) => item.label == 'Congé',
    );
    final recurringAbsences = [
      RecurringAbsence(
        id: _uuid.v4(),
        employeeId: employees[2].id,
        reasonId: recurringAbsenceReason.id,
        comment: 'Récurrent',
      ),
    ];

    final reportReasons = {
      'Maladie': absenceReasons
          .firstWhere((item) => item.label == 'Maladie')
          .id,
      'Absence injustifiée': absenceReasons
          .firstWhere((item) => item.label == 'Absence injustifiée')
          .id,
      'Congé': recurringAbsenceReason.id,
    };

    final reports = List.generate(7, (index) {
      final date = startOfDay(now.subtract(Duration(days: 6 - index)));
      final lateEntries = <LateEntry>[
        LateEntry(
          id: _uuid.v4(),
          employeeId: employees[index % employees.length].id,
          arrivalTime: '08:${(20 + index).toString().padLeft(2, '0')}',
          minutesLate: computeLateMinutes(
            '08:${(20 + index).toString().padLeft(2, '0')}',
          ),
          note: '',
        ),
      ];
      final absenceEntries = <AbsenceEntry>[
        if (index.isEven)
          AbsenceEntry(
            id: _uuid.v4(),
            employeeId: employees[(index + 2) % employees.length].id,
            reasonId: reportReasons[index % 4 == 0 ? 'Congé' : 'Maladie']!,
            comment: index % 4 == 0 ? 'Récurrent' : '',
          ),
      ];
      return DailyReport(
        id: _uuid.v4(),
        dateIso: civilDate(date),
        lateEntries: lateEntries,
        absenceEntries: absenceEntries,
        visitorCount: 8 + index,
        introText: buildReportIntro(date),
        status: index == 6 ? ReportStatus.draft : ReportStatus.finalized,
        createdBy: adminId,
        createdAtIso: date.toIso8601String(),
        updatedAtIso: date.toIso8601String(),
      );
    });

    return CrfcState(
      users: [
        AppUser(
          id: adminId,
          firstName: 'Admin',
          lastName: 'CRFC',
          email: 'admin@crfc.local',
          passwordHash: _hashPassword('Admin@2026'),
          jobTitle: 'Administrateur',
          role: UserRole.admin,
          isActive: true,
          createdAtIso: now.toIso8601String(),
          createdBy: 'system',
        ),
        AppUser(
          id: _uuid.v4(),
          firstName: 'Agent',
          lastName: 'Pointage',
          email: 'agent@crfc.local',
          passwordHash: _hashPassword('Agent@2026'),
          jobTitle: 'Agent de saisie',
          role: UserRole.agent,
          isActive: true,
          createdAtIso: now.toIso8601String(),
          createdBy: adminId,
        ),
      ],
      employees: employees,
      absenceReasons: absenceReasons,
      recurringAbsences: recurringAbsences,
      reports: reports,
      managedFiles: const [],
      preferences: const AppPreferences(isDarkMode: false),
    );
  }

  static String _hashPassword(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  String _averageArrivalTime(List<LateEntry> entries) {
    final totalMinutes = entries.fold<int>(0, (sum, entry) {
      final parts = entry.arrivalTime.split(':');
      return sum + (int.parse(parts[0]) * 60) + int.parse(parts[1]);
    });
    final average = totalMinutes ~/ entries.length;
    final hours = average ~/ 60;
    final minutes = average % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
