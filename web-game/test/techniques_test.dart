import 'package:alphadoku/ui/techniques.dart';
import 'package:alphadoku/ui/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reference searches aliases and expands an offline example', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: alphadokuTheme(), home: const TechniquesScreen()),
    );
    await tester.enterText(find.byType(TextField), 'XY-Wing');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Y-Wing'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pivot {A,B}'), findsOneWidget);
    expect(find.textContaining('BOTH wings'), findsOneWidget);
    expect(techniqueReference.length, 12);
    expect(tester.takeException(), isNull);
  });
}
