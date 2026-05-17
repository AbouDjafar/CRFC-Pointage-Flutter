import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/formatters.dart';
import 'app_database.dart';
import 'models.dart';

abstract class LocalStateStore {
  Future<CrfcState?> load();
  Future<void> save(CrfcState state);
}

class DriftLocalStateStore implements LocalStateStore {
  DriftLocalStateStore(this._database);

  static const _stateKey = 'app_state_v1';

  final AppDatabase _database;

  @override
  Future<CrfcState?> load() async {
    final record = await (_database.select(
      _database.stateRecords,
    )..where((tbl) => tbl.key.equals(_stateKey))).getSingleOrNull();
    if (record == null) {
      return null;
    }
    return CrfcState.fromEncodedJson(record.json);
  }

  @override
  Future<void> save(CrfcState state) {
    return _database
        .into(_database.stateRecords)
        .insertOnConflictUpdate(
          StateRecordsCompanion.insert(
            key: _stateKey,
            json: state.toEncodedJson(),
          ),
        );
  }
}

abstract class SessionStorage {
  Future<String?> readCurrentUserId();
  Future<void> writeCurrentUserId(String userId);
  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _sessionKey = 'current_user_id';

  @override
  Future<void> clear() => _storage.delete(key: _sessionKey);

  @override
  Future<String?> readCurrentUserId() => _storage.read(key: _sessionKey);

  @override
  Future<void> writeCurrentUserId(String userId) =>
      _storage.write(key: _sessionKey, value: userId);
}

class ImportedEmployeeBatch {
  const ImportedEmployeeBatch({
    required this.employees,
    required this.addedCount,
    required this.updatedCount,
    required this.sourceName,
  });

  final List<Employee> employees;
  final int addedCount;
  final int updatedCount;
  final String sourceName;
}

class EmployeeImportService {
  Future<ImportedEmployeeBatch?> pickAndImport(
    List<Employee> existingEmployees,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.single;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    return importFromBytes(
      bytes: bytes,
      sourceName: file.name,
      existingEmployees: existingEmployees,
    );
  }

  ImportedEmployeeBatch importFromBytes({
    required Uint8List bytes,
    required String sourceName,
    required List<Employee> existingEmployees,
  }) {
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables.values.firstOrNull;
    if (sheet == null || sheet.rows.isEmpty) {
      throw StateError(
        'Le fichier Excel ne contient aucune feuille exploitable.',
      );
    }

    final headerRowIndex = _detectHeaderRow(sheet.rows);
    final nameColumnIndex = _detectNameColumn(sheet.rows[headerRowIndex]);

    final existingByName = <String, Employee>{
      for (final employee in existingEmployees)
        normalizeText(employee.fullName): employee,
    };

    var addedCount = 0;
    var updatedCount = 0;
    final merged = existingEmployees.toList();

    for (final row in sheet.rows.skip(headerRowIndex + 1)) {
      if (nameColumnIndex >= row.length) {
        continue;
      }
      final rawValue = row[nameColumnIndex]?.value?.toString().trim() ?? '';
      if (rawValue.isEmpty) {
        continue;
      }
      final normalized = normalizeText(rawValue);
      final parts = splitHumanName(rawValue);
      final existing = existingByName[normalized];
      if (existing == null) {
        merged.add(
          Employee(
            id: 'emp-${DateTime.now().microsecondsSinceEpoch}-${addedCount + 1}',
            fullName: rawValue.replaceAll(RegExp(r'\s+'), ' '),
            firstName: parts.firstName,
            lastName: parts.lastName,
            isActive: true,
            needsReview: parts.needsReview,
            importSource: sourceName,
            importedAtIso: DateTime.now().toIso8601String(),
          ),
        );
        addedCount++;
      } else {
        final index = merged.indexWhere((item) => item.id == existing.id);
        merged[index] = existing.copyWith(
          fullName: rawValue.replaceAll(RegExp(r'\s+'), ' '),
          firstName: parts.firstName,
          lastName: parts.lastName,
          isActive: true,
          needsReview: parts.needsReview,
          importSource: sourceName,
          importedAtIso: DateTime.now().toIso8601String(),
        );
        updatedCount++;
      }
    }

    merged.sort((a, b) => a.fullName.compareTo(b.fullName));

    return ImportedEmployeeBatch(
      employees: merged,
      addedCount: addedCount,
      updatedCount: updatedCount,
      sourceName: sourceName,
    );
  }

  int _detectHeaderRow(List<List<Data?>> rows) {
    for (var rowIndex = 0; rowIndex < rows.length && rowIndex < 4; rowIndex++) {
      final rowValues = rows[rowIndex]
          .map((cell) => normalizeText(cell?.value?.toString() ?? ''))
          .toList();
      if (rowValues.any(
        (value) =>
            const {'nom complet', 'full name', 'name', 'nom'}.contains(value),
      )) {
        return rowIndex;
      }
    }
    return 0;
  }

  int _detectNameColumn(List<Data?> row) {
    final values = row
        .map((cell) => normalizeText(cell?.value?.toString() ?? ''))
        .toList();
    for (var index = 0; index < values.length; index++) {
      if (const {
        'nom complet',
        'full name',
        'name',
        'nom',
      }.contains(values[index])) {
        return index;
      }
    }
    for (var index = 0; index < values.length; index++) {
      if (values[index].isNotEmpty) {
        return index;
      }
    }
    return 0;
  }
}

class ExportService {
  Future<ManagedFile> generatePdf({
    required DailyReport report,
    required CrfcState state,
    required AppUser author,
  }) async {
    final directory = await _ensureDirectory('pdf');
    final fileName = 'rapport-pointage-${report.dateIso}.pdf';
    final file = File(p.join(directory.path, fileName));

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'CRFC',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Rapport journalier de pointage'),
          pw.Text('Date : ${formatLongDate(report.date)}'),
          pw.Text('Auteur : ${author.fullName} - ${author.jobTitle}'),
          pw.SizedBox(height: 16),
          pw.Text(report.introText),
          pw.SizedBox(height: 20),
          pw.Text(
            'Retards',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const ['Employé', 'Arrivée', 'Retard'],
            data: report.lateEntries.map((entry) {
              final employee = state.employeeById(entry.employeeId);
              return [
                employee?.fullName ?? 'Inconnu',
                entry.arrivalTime,
                '${entry.minutesLate} min',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Absences',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const ['Employé', 'Motif', 'Commentaire'],
            data: report.absenceEntries.map((entry) {
              final employee = state.employeeById(entry.employeeId);
              final reason = state.reasonById(entry.reasonId);
              return [
                employee?.fullName ?? 'Inconnu',
                reason?.label ?? 'Motif',
                entry.comment,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Visiteurs : ${report.visitorCount}'),
        ],
      ),
    );

    await file.writeAsBytes(await pdf.save());
    final now = DateTime.now().toIso8601String();
    return ManagedFile(
      id: 'file-${DateTime.now().microsecondsSinceEpoch}',
      type: ManagedFileType.pdf,
      name: fileName,
      path: file.path,
      mimeType: 'application/pdf',
      createdAtIso: now,
      updatedAtIso: now,
      relatedReportId: report.id,
    );
  }

  Future<ManagedFile> generateExcel({
    required CrfcState state,
    required DateTime start,
    required DateTime end,
  }) async {
    final directory = await _ensureDirectory('excel');
    final fileName =
        'synthese-rapports-${civilDate(start)}_${civilDate(end)}.xlsx';
    final file = File(p.join(directory.path, fileName));
    final workbook = Excel.createExcel();
    final synthese = workbook['Synthese'];
    final totaux = workbook['Totaux'];
    final retards = workbook['Retards'];
    final absences = workbook['Absences'];

    final filteredReports = state.reports.where((report) {
      return !report.date.isBefore(startOfDay(start)) &&
          !report.date.isAfter(startOfDay(end));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    synthese.appendRow([
      TextCellValue('Période'),
      TextCellValue('${formatShortDate(start)} - ${formatShortDate(end)}'),
    ]);
    synthese.appendRow([
      TextCellValue('Rapports'),
      IntCellValue(filteredReports.length),
    ]);

    final totalLate = filteredReports.fold<int>(
      0,
      (sum, item) => sum + item.lateEntries.length,
    );
    final totalAbsence = filteredReports.fold<int>(
      0,
      (sum, item) => sum + item.absenceEntries.length,
    );
    final totalVisitors = filteredReports.fold<int>(
      0,
      (sum, item) => sum + item.visitorCount,
    );
    totaux.appendRow([TextCellValue('Indicateur'), TextCellValue('Valeur')]);
    totaux.appendRow([TextCellValue('Retards'), IntCellValue(totalLate)]);
    totaux.appendRow([TextCellValue('Absences'), IntCellValue(totalAbsence)]);
    totaux.appendRow([TextCellValue('Visiteurs'), IntCellValue(totalVisitors)]);

    retards.appendRow([
      TextCellValue('Date'),
      TextCellValue('Employé'),
      TextCellValue('Arrivée'),
      TextCellValue('Retard (min)'),
    ]);
    absences.appendRow([
      TextCellValue('Date'),
      TextCellValue('Employé'),
      TextCellValue('Motif'),
      TextCellValue('Commentaire'),
    ]);

    for (final report in filteredReports) {
      for (final late in report.lateEntries) {
        final employee = state.employeeById(late.employeeId);
        retards.appendRow([
          TextCellValue(report.dateIso),
          TextCellValue(employee?.fullName ?? 'Inconnu'),
          TextCellValue(late.arrivalTime),
          IntCellValue(late.minutesLate),
        ]);
      }
      for (final absence in report.absenceEntries) {
        final employee = state.employeeById(absence.employeeId);
        final reason = state.reasonById(absence.reasonId);
        absences.appendRow([
          TextCellValue(report.dateIso),
          TextCellValue(employee?.fullName ?? 'Inconnu'),
          TextCellValue(reason?.label ?? 'Motif'),
          TextCellValue(absence.comment),
        ]);
      }
    }

    final bytes = workbook.encode();
    if (bytes == null) {
      throw StateError('La génération Excel a échoué.');
    }
    await file.writeAsBytes(bytes);

    final now = DateTime.now().toIso8601String();
    return ManagedFile(
      id: 'file-${DateTime.now().microsecondsSinceEpoch}',
      type: ManagedFileType.excel,
      name: fileName,
      path: file.path,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      createdAtIso: now,
      updatedAtIso: now,
      periodStartIso: civilDate(start),
      periodEndIso: civilDate(end),
    );
  }

  Future<ManagedFile> renameManagedFile(
    ManagedFile file,
    String newName,
  ) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Le nom du fichier ne peut pas être vide.');
    }
    final extension = p.extension(file.path);
    final target = p.join(
      p.dirname(file.path),
      cleanName.endsWith(extension) ? cleanName : '$cleanName$extension',
    );
    final renamed = await File(file.path).rename(target);
    return file.copyWith(
      name: p.basename(renamed.path),
      path: renamed.path,
      updatedAtIso: DateTime.now().toIso8601String(),
    );
  }

  Future<void> deleteManagedFile(ManagedFile file) async {
    final target = File(file.path);
    if (await target.exists()) {
      await target.delete();
    }
  }

  Future<void> openManagedFile(ManagedFile file) async {
    await OpenFilex.open(file.path);
  }

  Future<void> shareManagedFile(ManagedFile file) async {
    await Share.shareXFiles([XFile(file.path)], text: file.name);
  }

  Future<Directory> _ensureDirectory(String name) async {
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(base.path, 'exports', name));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
