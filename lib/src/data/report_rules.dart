import '../core/formatters.dart';
import 'models.dart';

List<AbsenceEntry> buildRecurringAbsenceEntries({
  required CrfcState state,
  required String defaultReasonId,
  required String Function() createId,
}) {
  return state.recurringAbsences
      .where((item) => state.employeeById(item.employeeId)?.isActive ?? false)
      .map(
        (item) => AbsenceEntry(
          id: createId(),
          employeeId: item.employeeId,
          reasonId: item.reasonId.isNotEmpty ? item.reasonId : defaultReasonId,
          comment: item.comment,
        ),
      )
      .toList();
}

DailyReport createDraftReport({
  required CrfcState state,
  required AppUser author,
  required DateTime date,
  required String defaultReasonId,
  required String Function() createId,
  DateTime? now,
}) {
  final timestamp = (now ?? DateTime.now()).toIso8601String();
  final normalizedDate = startOfDay(date);
  return DailyReport(
    id: createId(),
    dateIso: civilDate(normalizedDate),
    lateEntries: const [],
    absenceEntries: buildRecurringAbsenceEntries(
      state: state,
      defaultReasonId: defaultReasonId,
      createId: createId,
    ),
    visitorCount: 0,
    introText: buildReportIntro(normalizedDate),
    status: ReportStatus.draft,
    createdBy: author.id,
    createdAtIso: timestamp,
    updatedAtIso: timestamp,
  );
}

void ensureReportEditable(DailyReport report) {
  if (report.status == ReportStatus.finalized) {
    throw StateError('Le rapport est finalisé et verrouillé.');
  }
}

void ensureEmployeeEligible({
  required CrfcState state,
  required DailyReport report,
  required String employeeId,
}) {
  final employee = state.employeeById(employeeId);
  if (employee == null || !employee.isActive) {
    throw StateError('Employé inactif ou introuvable.');
  }
  final inLate = report.lateEntries.any(
    (entry) => entry.employeeId == employeeId,
  );
  final inAbsence = report.absenceEntries.any(
    (entry) => entry.employeeId == employeeId,
  );
  if (inLate || inAbsence) {
    throw StateError('Cet employé existe déjà dans le rapport du jour.');
  }
}
