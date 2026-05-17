import 'dart:math';

import 'package:intl/intl.dart';

DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String civilDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

DateTime parseCivilDate(String value) => DateTime.parse(value);

String formatLongDate(DateTime value) =>
    DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(value);

String formatShortDate(DateTime value) =>
    DateFormat('dd/MM/yyyy', 'fr_FR').format(value);

String formatMonthYear(DateTime value) =>
    DateFormat('MMMM yyyy', 'fr_FR').format(value);

String formatTimeLabel(DateTime value) =>
    DateFormat('HH:mm', 'fr_FR').format(value);

String normalizeText(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'[éèêë]', unicode: true), 'e')
    .replaceAll(RegExp(r'[àâä]', unicode: true), 'a')
    .replaceAll(RegExp(r'[ùûü]', unicode: true), 'u')
    .replaceAll(RegExp(r'[ôö]', unicode: true), 'o')
    .replaceAll(RegExp(r'[îï]', unicode: true), 'i')
    .replaceAll(RegExp(r'[ç]', unicode: true), 'c');

int computeLateMinutes(String arrivalTime, {String referenceTime = '08:15'}) {
  final arrival = _parseMinutes(arrivalTime);
  final reference = _parseMinutes(referenceTime);
  return max(0, arrival - reference);
}

String humanizeDurationMinutes(int minutes) {
  if (minutes <= 0) {
    return '0 min';
  }
  if (minutes < 60) {
    return '$minutes min';
  }
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  return remaining == 0 ? '${hours}h' : '${hours}h$remaining';
}

String buildReportIntro(DateTime date) {
  final label = DateFormat('d MMMM yyyy', 'fr_FR').format(date);
  return 'Veuillez trouver ci-joint le rapport journalier de pointage du $label.';
}

String slugifyFileName(String value) {
  final normalized = normalizeText(
    value,
  ).replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return normalized
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

({String firstName, String lastName, bool needsReview}) splitHumanName(
  String rawName,
) {
  final compact = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
  final parts = compact.split(' ').where((part) => part.isNotEmpty).toList();
  if (parts.length < 2) {
    return (firstName: compact, lastName: '', needsReview: true);
  }
  final firstName = parts.take(parts.length - 1).join(' ');
  final lastName = parts.last;
  return (
    firstName: firstName,
    lastName: lastName,
    needsReview:
        parts.length > 3 || firstName.length < 2 || lastName.length < 2,
  );
}

int _parseMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) {
    throw const FormatException('Heure invalide');
  }
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
    throw const FormatException('Heure invalide');
  }
  return (hours * 60) + minutes;
}
