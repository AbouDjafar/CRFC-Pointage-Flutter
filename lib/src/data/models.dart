import 'dart:convert';

import 'package:collection/collection.dart';

import '../core/formatters.dart';

enum UserRole { admin, agent }

enum ReportStatus { draft, finalized }

enum ManagedFileType { pdf, excel }

class AppPreferences {
  const AppPreferences({required this.isDarkMode, this.lastLoginAtIso});

  final bool isDarkMode;
  final String? lastLoginAtIso;

  DateTime? get lastLoginAt =>
      lastLoginAtIso == null ? null : DateTime.tryParse(lastLoginAtIso!);

  AppPreferences copyWith({bool? isDarkMode, String? lastLoginAtIso}) {
    return AppPreferences(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lastLoginAtIso: lastLoginAtIso ?? this.lastLoginAtIso,
    );
  }

  Map<String, dynamic> toJson() => {
    'isDarkMode': isDarkMode,
    'lastLoginAtIso': lastLoginAtIso,
  };

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      lastLoginAtIso: json['lastLoginAtIso'] as String?,
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passwordHash,
    required this.jobTitle,
    required this.role,
    required this.isActive,
    required this.createdAtIso,
    required this.createdBy,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String passwordHash;
  final String jobTitle;
  final UserRole role;
  final bool isActive;
  final String createdAtIso;
  final String createdBy;

  String get fullName => '$firstName $lastName'.trim();
  String get shortLogin => email.split('@').first;
  String get initials {
    final first = firstName.isEmpty ? '' : firstName[0];
    final last = lastName.isEmpty ? '' : lastName[0];
    return (first + last).toUpperCase();
  }

  AppUser copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? passwordHash,
    String? jobTitle,
    UserRole? role,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      jobTitle: jobTitle ?? this.jobTitle,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAtIso: createdAtIso,
      createdBy: createdBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'passwordHash': passwordHash,
    'jobTitle': jobTitle,
    'role': role.name,
    'isActive': isActive,
    'createdAtIso': createdAtIso,
    'createdBy': createdBy,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    passwordHash: json['passwordHash'] as String,
    jobTitle: json['jobTitle'] as String,
    role: UserRole.values.byName(json['role'] as String),
    isActive: json['isActive'] as bool,
    createdAtIso: json['createdAtIso'] as String,
    createdBy: json['createdBy'] as String,
  );
}

class Employee {
  const Employee({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.needsReview,
    required this.importSource,
    required this.importedAtIso,
  });

  final String id;
  final String fullName;
  final String firstName;
  final String lastName;
  final bool isActive;
  final bool needsReview;
  final String importSource;
  final String importedAtIso;

  Employee copyWith({
    String? fullName,
    String? firstName,
    String? lastName,
    bool? isActive,
    bool? needsReview,
    String? importSource,
    String? importedAtIso,
  }) {
    return Employee(
      id: id,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isActive: isActive ?? this.isActive,
      needsReview: needsReview ?? this.needsReview,
      importSource: importSource ?? this.importSource,
      importedAtIso: importedAtIso ?? this.importedAtIso,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'firstName': firstName,
    'lastName': lastName,
    'isActive': isActive,
    'needsReview': needsReview,
    'importSource': importSource,
    'importedAtIso': importedAtIso,
  };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    isActive: json['isActive'] as bool,
    needsReview: json['needsReview'] as bool,
    importSource: json['importSource'] as String,
    importedAtIso: json['importedAtIso'] as String,
  );
}

class AbsenceReason {
  const AbsenceReason({required this.id, required this.label});

  final String id;
  final String label;

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  factory AbsenceReason.fromJson(Map<String, dynamic> json) =>
      AbsenceReason(id: json['id'] as String, label: json['label'] as String);
}

class RecurringAbsence {
  const RecurringAbsence({
    required this.id,
    required this.employeeId,
    required this.reasonId,
    required this.comment,
  });

  final String id;
  final String employeeId;
  final String reasonId;
  final String comment;

  RecurringAbsence copyWith({
    String? employeeId,
    String? reasonId,
    String? comment,
  }) {
    return RecurringAbsence(
      id: id,
      employeeId: employeeId ?? this.employeeId,
      reasonId: reasonId ?? this.reasonId,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'reasonId': reasonId,
    'comment': comment,
  };

  factory RecurringAbsence.fromJson(Map<String, dynamic> json) =>
      RecurringAbsence(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        reasonId: json['reasonId'] as String,
        comment: json['comment'] as String? ?? '',
      );
}

class LateEntry {
  const LateEntry({
    required this.id,
    required this.employeeId,
    required this.arrivalTime,
    required this.minutesLate,
    required this.note,
  });

  final String id;
  final String employeeId;
  final String arrivalTime;
  final int minutesLate;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'arrivalTime': arrivalTime,
    'minutesLate': minutesLate,
    'note': note,
  };

  factory LateEntry.fromJson(Map<String, dynamic> json) => LateEntry(
    id: json['id'] as String,
    employeeId: json['employeeId'] as String,
    arrivalTime: json['arrivalTime'] as String,
    minutesLate: json['minutesLate'] as int,
    note: json['note'] as String? ?? '',
  );
}

class AbsenceEntry {
  const AbsenceEntry({
    required this.id,
    required this.employeeId,
    required this.reasonId,
    required this.comment,
  });

  final String id;
  final String employeeId;
  final String reasonId;
  final String comment;

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'reasonId': reasonId,
    'comment': comment,
  };

  factory AbsenceEntry.fromJson(Map<String, dynamic> json) => AbsenceEntry(
    id: json['id'] as String,
    employeeId: json['employeeId'] as String,
    reasonId: json['reasonId'] as String,
    comment: json['comment'] as String? ?? '',
  );
}

class DailyReport {
  const DailyReport({
    required this.id,
    required this.dateIso,
    required this.lateEntries,
    required this.absenceEntries,
    required this.visitorCount,
    required this.introText,
    required this.status,
    required this.createdBy,
    required this.createdAtIso,
    required this.updatedAtIso,
    this.pdfPath,
  });

  final String id;
  final String dateIso;
  final List<LateEntry> lateEntries;
  final List<AbsenceEntry> absenceEntries;
  final int visitorCount;
  final String introText;
  final ReportStatus status;
  final String createdBy;
  final String createdAtIso;
  final String updatedAtIso;
  final String? pdfPath;

  DateTime get date => parseCivilDate(dateIso);

  DailyReport copyWith({
    List<LateEntry>? lateEntries,
    List<AbsenceEntry>? absenceEntries,
    int? visitorCount,
    String? introText,
    ReportStatus? status,
    String? updatedAtIso,
    String? pdfPath,
  }) {
    return DailyReport(
      id: id,
      dateIso: dateIso,
      lateEntries: lateEntries ?? this.lateEntries,
      absenceEntries: absenceEntries ?? this.absenceEntries,
      visitorCount: visitorCount ?? this.visitorCount,
      introText: introText ?? this.introText,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAtIso: createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dateIso': dateIso,
    'lateEntries': lateEntries.map((item) => item.toJson()).toList(),
    'absenceEntries': absenceEntries.map((item) => item.toJson()).toList(),
    'visitorCount': visitorCount,
    'introText': introText,
    'status': status.name,
    'createdBy': createdBy,
    'createdAtIso': createdAtIso,
    'updatedAtIso': updatedAtIso,
    'pdfPath': pdfPath,
  };

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
    id: json['id'] as String,
    dateIso: json['dateIso'] as String,
    lateEntries: (json['lateEntries'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => LateEntry.fromJson(item as Map<String, dynamic>))
        .toList(),
    absenceEntries: (json['absenceEntries'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => AbsenceEntry.fromJson(item as Map<String, dynamic>))
        .toList(),
    visitorCount: json['visitorCount'] as int? ?? 0,
    introText: json['introText'] as String,
    status: ReportStatus.values.byName(json['status'] as String),
    createdBy: json['createdBy'] as String,
    createdAtIso: json['createdAtIso'] as String,
    updatedAtIso: json['updatedAtIso'] as String,
    pdfPath: json['pdfPath'] as String?,
  );
}

class ManagedFile {
  const ManagedFile({
    required this.id,
    required this.type,
    required this.name,
    required this.path,
    required this.mimeType,
    required this.createdAtIso,
    required this.updatedAtIso,
    this.relatedReportId,
    this.periodStartIso,
    this.periodEndIso,
  });

  final String id;
  final ManagedFileType type;
  final String name;
  final String path;
  final String mimeType;
  final String createdAtIso;
  final String updatedAtIso;
  final String? relatedReportId;
  final String? periodStartIso;
  final String? periodEndIso;

  ManagedFile copyWith({String? name, String? path, String? updatedAtIso}) {
    return ManagedFile(
      id: id,
      type: type,
      name: name ?? this.name,
      path: path ?? this.path,
      mimeType: mimeType,
      createdAtIso: createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      relatedReportId: relatedReportId,
      periodStartIso: periodStartIso,
      periodEndIso: periodEndIso,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'path': path,
    'mimeType': mimeType,
    'createdAtIso': createdAtIso,
    'updatedAtIso': updatedAtIso,
    'relatedReportId': relatedReportId,
    'periodStartIso': periodStartIso,
    'periodEndIso': periodEndIso,
  };

  factory ManagedFile.fromJson(Map<String, dynamic> json) => ManagedFile(
    id: json['id'] as String,
    type: ManagedFileType.values.byName(json['type'] as String),
    name: json['name'] as String,
    path: json['path'] as String,
    mimeType: json['mimeType'] as String,
    createdAtIso: json['createdAtIso'] as String,
    updatedAtIso: json['updatedAtIso'] as String,
    relatedReportId: json['relatedReportId'] as String?,
    periodStartIso: json['periodStartIso'] as String?,
    periodEndIso: json['periodEndIso'] as String?,
  );
}

class CrfcState {
  const CrfcState({
    required this.users,
    required this.employees,
    required this.absenceReasons,
    required this.recurringAbsences,
    required this.reports,
    required this.managedFiles,
    required this.preferences,
    this.currentUserId,
  });

  final List<AppUser> users;
  final List<Employee> employees;
  final List<AbsenceReason> absenceReasons;
  final List<RecurringAbsence> recurringAbsences;
  final List<DailyReport> reports;
  final List<ManagedFile> managedFiles;
  final AppPreferences preferences;
  final String? currentUserId;

  AppUser? get currentUser =>
      users.firstWhereOrNull((user) => user.id == currentUserId);

  List<Employee> get activeEmployees =>
      employees.where((employee) => employee.isActive).toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

  DailyReport? reportForDate(DateTime date) =>
      reports.firstWhereOrNull((report) => isSameDay(report.date, date));

  Employee? employeeById(String id) =>
      employees.firstWhereOrNull((employee) => employee.id == id);

  AbsenceReason? reasonById(String id) =>
      absenceReasons.firstWhereOrNull((reason) => reason.id == id);

  AppUser? userById(String id) =>
      users.firstWhereOrNull((user) => user.id == id);

  CrfcState copyWith({
    List<AppUser>? users,
    List<Employee>? employees,
    List<AbsenceReason>? absenceReasons,
    List<RecurringAbsence>? recurringAbsences,
    List<DailyReport>? reports,
    List<ManagedFile>? managedFiles,
    AppPreferences? preferences,
    String? currentUserId,
  }) {
    return CrfcState(
      users: users ?? this.users,
      employees: employees ?? this.employees,
      absenceReasons: absenceReasons ?? this.absenceReasons,
      recurringAbsences: recurringAbsences ?? this.recurringAbsences,
      reports: reports ?? this.reports,
      managedFiles: managedFiles ?? this.managedFiles,
      preferences: preferences ?? this.preferences,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  Map<String, dynamic> toJson({bool includeSession = false}) => {
    'users': users.map((item) => item.toJson()).toList(),
    'employees': employees.map((item) => item.toJson()).toList(),
    'absenceReasons': absenceReasons.map((item) => item.toJson()).toList(),
    'recurringAbsences': recurringAbsences
        .map((item) => item.toJson())
        .toList(),
    'reports': reports.map((item) => item.toJson()).toList(),
    'managedFiles': managedFiles.map((item) => item.toJson()).toList(),
    'preferences': preferences.toJson(),
    if (includeSession) 'currentUserId': currentUserId,
  };

  String toEncodedJson() => jsonEncode(toJson());

  factory CrfcState.fromJson(Map<String, dynamic> json) => CrfcState(
    users: (json['users'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
        .toList(),
    employees: (json['employees'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Employee.fromJson(item as Map<String, dynamic>))
        .toList(),
    absenceReasons: (json['absenceReasons'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => AbsenceReason.fromJson(item as Map<String, dynamic>))
        .toList(),
    recurringAbsences:
        (json['recurringAbsences'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (item) => RecurringAbsence.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
    reports: (json['reports'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => DailyReport.fromJson(item as Map<String, dynamic>))
        .toList(),
    managedFiles: (json['managedFiles'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => ManagedFile.fromJson(item as Map<String, dynamic>))
        .toList(),
    preferences: AppPreferences.fromJson(
      json['preferences'] as Map<String, dynamic>? ?? const {},
    ),
    currentUserId: json['currentUserId'] as String?,
  );

  factory CrfcState.fromEncodedJson(String encoded) =>
      CrfcState.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
}

class RankedEmployee {
  const RankedEmployee({
    required this.employee,
    required this.count,
    required this.averageArrivalTime,
  });

  final Employee employee;
  final int count;
  final String averageArrivalTime;
}

class ReasonShare {
  const ReasonShare({
    required this.reason,
    required this.count,
    required this.percentage,
  });

  final AbsenceReason reason;
  final int count;
  final double percentage;
}

class TrendPoint {
  const TrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.reportCount,
    required this.totalLate,
    required this.totalAbsence,
    required this.totalVisitors,
    required this.totalIncidents,
    required this.averageLateMinutes,
    required this.reasonShares,
    required this.topLateEmployees,
    required this.trendPoints,
  });

  final int reportCount;
  final int totalLate;
  final int totalAbsence;
  final int totalVisitors;
  final int totalIncidents;
  final double averageLateMinutes;
  final List<ReasonShare> reasonShares;
  final List<RankedEmployee> topLateEmployees;
  final List<TrendPoint> trendPoints;
}
