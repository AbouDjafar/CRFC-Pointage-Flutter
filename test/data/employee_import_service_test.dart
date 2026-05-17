import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crfc_pointage_flutter/src/data/models.dart';
import 'package:crfc_pointage_flutter/src/data/services.dart';

void main() {
  late EmployeeImportService service;

  setUp(() {
    service = EmployeeImportService();
  });

  test('imports employees from the recognized full-name column', () {
    final workbook = Excel.createExcel();
    final sheet = workbook['Sheet1'];
    sheet.appendRow([TextCellValue('Nom complet')]);
    sheet.appendRow([TextCellValue('Jean Dupont')]);
    sheet.appendRow([TextCellValue('Amina')]);

    final result = service.importFromBytes(
      bytes: Uint8List.fromList(workbook.encode()!),
      sourceName: 'personnel.xlsx',
      existingEmployees: const [],
    );

    expect(result.addedCount, 2);
    expect(result.updatedCount, 0);
    expect(
      result.employees.map((employee) => employee.fullName),
      containsAll(['Jean Dupont', 'Amina']),
    );
    expect(
      result.employees
          .firstWhere((employee) => employee.fullName == 'Amina')
          .needsReview,
      isTrue,
    );
  });

  test(
    'falls back to the first non-empty header when no standard label exists',
    () {
      final workbook = Excel.createExcel();
      final sheet = workbook['Sheet1'];
      sheet.appendRow([TextCellValue(''), TextCellValue('Personnel')]);
      sheet.appendRow([TextCellValue(''), TextCellValue('Sarah Benali')]);

      final result = service.importFromBytes(
        bytes: Uint8List.fromList(workbook.encode()!),
        sourceName: 'fallback.xlsx',
        existingEmployees: const [],
      );

      expect(result.addedCount, 1);
      expect(result.employees.single.fullName, 'Sarah Benali');
    },
  );

  test(
    'updates an existing employee instead of duplicating the same normalized name',
    () {
      final workbook = Excel.createExcel();
      final sheet = workbook['Sheet1'];
      sheet.appendRow([TextCellValue('Full Name')]);
      sheet.appendRow([TextCellValue('Jean   Dupont')]);

      final existing = [
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
      ];

      final result = service.importFromBytes(
        bytes: Uint8List.fromList(workbook.encode()!),
        sourceName: 'update.xlsx',
        existingEmployees: existing,
      );

      expect(result.addedCount, 0);
      expect(result.updatedCount, 1);
      expect(result.employees.single.id, 'emp-1');
      expect(result.employees.single.isActive, isTrue);
      expect(result.employees.single.importSource, 'update.xlsx');
    },
  );
}
