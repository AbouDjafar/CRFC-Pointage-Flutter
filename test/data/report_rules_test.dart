import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crfc_pointage_flutter/src/data/models.dart';
import 'package:crfc_pointage_flutter/src/data/report_rules.dart';

CrfcState buildState({
  List<Employee>? employees,
  List<RecurringAbsence>? recurringAbsences,
}) {
  return CrfcState(
    users: const [],
    employees:
        employees ??
        const [
          Employee(
            id: 'emp-1',
            fullName: 'Jean Dupont',
            firstName: 'Jean',
            lastName: 'Dupont',
            isActive: true,
            needsReview: false,
            importSource: 'seed',
            importedAtIso: '2026-05-17T08:00:00.000',
          ),
          Employee(
            id: 'emp-2',
            fullName: 'Sarah Benali',
            firstName: 'Sarah',
            lastName: 'Benali',
            isActive: true,
            needsReview: false,
            importSource: 'seed',
            importedAtIso: '2026-05-17T08:00:00.000',
          ),
        ],
    absenceReasons: const [
      AbsenceReason(id: 'reason-1', label: 'Congé'),
      AbsenceReason(id: 'reason-2', label: 'Maladie'),
    ],
    recurringAbsences:
        recurringAbsences ??
        const [
          RecurringAbsence(
            id: 'rec-1',
            employeeId: 'emp-2',
            reasonId: 'reason-1',
            comment: 'Récurrent',
          ),
        ],
    reports: const [],
    managedFiles: const [],
    preferences: const AppPreferences(isDarkMode: false),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  test(
    'createDraftReport preloads recurring absences for active employees only',
    () {
      final state = buildState(
        employees: const [
          Employee(
            id: 'emp-1',
            fullName: 'Jean Dupont',
            firstName: 'Jean',
            lastName: 'Dupont',
            isActive: true,
            needsReview: false,
            importSource: 'seed',
            importedAtIso: '2026-05-17T08:00:00.000',
          ),
          Employee(
            id: 'emp-2',
            fullName: 'Sarah Benali',
            firstName: 'Sarah',
            lastName: 'Benali',
            isActive: false,
            needsReview: false,
            importSource: 'seed',
            importedAtIso: '2026-05-17T08:00:00.000',
          ),
        ],
      );

      final report = createDraftReport(
        state: state,
        author: const AppUser(
          id: 'user-1',
          firstName: 'Admin',
          lastName: 'CRFC',
          email: 'admin@crfc.local',
          passwordHash: 'hash',
          jobTitle: 'Administrateur',
          role: UserRole.admin,
          isActive: true,
          createdAtIso: '2026-05-17T08:00:00.000',
          createdBy: 'system',
        ),
        date: DateTime(2026, 6, 1),
        defaultReasonId: 'reason-2',
        createId: () => 'generated-id',
        now: DateTime(2026, 5, 17, 9),
      );

      expect(report.status, ReportStatus.draft);
      expect(report.visitorCount, 0);
      expect(report.absenceEntries, isEmpty);
    },
  );

  test('buildRecurringAbsenceEntries uses the default reason when missing', () {
    final state = buildState(
      recurringAbsences: const [
        RecurringAbsence(
          id: 'rec-1',
          employeeId: 'emp-2',
          reasonId: '',
          comment: 'A vérifier',
        ),
      ],
    );

    final entries = buildRecurringAbsenceEntries(
      state: state,
      defaultReasonId: 'reason-2',
      createId: () => 'entry-1',
    );

    expect(entries.single.reasonId, 'reason-2');
    expect(entries.single.comment, 'A vérifier');
  });

  test('ensureEmployeeEligible rejects duplicates and inactive employees', () {
    final state = buildState(
      employees: const [
        Employee(
          id: 'emp-1',
          fullName: 'Jean Dupont',
          firstName: 'Jean',
          lastName: 'Dupont',
          isActive: false,
          needsReview: false,
          importSource: 'seed',
          importedAtIso: '2026-05-17T08:00:00.000',
        ),
      ],
      recurringAbsences: const [],
    );

    final duplicateReport = DailyReport(
      id: 'report-1',
      dateIso: '2026-06-01',
      lateEntries: const [
        LateEntry(
          id: 'late-1',
          employeeId: 'emp-1',
          arrivalTime: '08:30',
          minutesLate: 15,
          note: '',
        ),
      ],
      absenceEntries: const [],
      visitorCount: 0,
      introText: 'Intro',
      status: ReportStatus.draft,
      createdBy: 'user-1',
      createdAtIso: '2026-05-17T08:00:00.000',
      updatedAtIso: '2026-05-17T08:00:00.000',
    );

    expect(
      () => ensureEmployeeEligible(
        state: state,
        report: duplicateReport,
        employeeId: 'emp-1',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('ensureReportEditable blocks finalized reports', () {
    final report = DailyReport(
      id: 'report-1',
      dateIso: '2026-06-01',
      lateEntries: const [],
      absenceEntries: const [],
      visitorCount: 0,
      introText: 'Intro',
      status: ReportStatus.finalized,
      createdBy: 'user-1',
      createdAtIso: '2026-05-17T08:00:00.000',
      updatedAtIso: '2026-05-17T08:00:00.000',
    );

    expect(() => ensureReportEditable(report), throwsA(isA<StateError>()));
  });
}
