import 'package:flutter_test/flutter_test.dart';

import 'package:crfc_pointage_flutter/src/core/formatters.dart';

void main() {
  test('computeLateMinutes uses 08:15 as the default business reference', () {
    expect(computeLateMinutes('08:15'), 0);
    expect(computeLateMinutes('08:14'), 0);
    expect(computeLateMinutes('08:30'), 15);
    expect(computeLateMinutes('09:00'), 45);
  });

  test('splitHumanName flags ambiguous names for manual review', () {
    final single = splitHumanName('Amina');
    final regular = splitHumanName('Jean Dupont');
    final long = splitHumanName('Marie Claire Anne Dupont');

    expect(single.firstName, 'Amina');
    expect(single.lastName, '');
    expect(single.needsReview, isTrue);

    expect(regular.firstName, 'Jean');
    expect(regular.lastName, 'Dupont');
    expect(regular.needsReview, isFalse);

    expect(long.needsReview, isTrue);
  });

  test('normalizeText folds accents and spacing for matching', () {
    expect(normalizeText('  Présence   Générale '), 'presence generale');
    expect(normalizeText('ÇA va'), 'ca va');
  });
}
