import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crfc_pointage_flutter/src/features/login_page.dart';

void main() {
  testWidgets('login page renders key branding and form labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    expect(find.text('CRFC Pointage'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('IDENTIFIANT OU EMAIL'), findsOneWidget);
  });
}
