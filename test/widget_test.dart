import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fabricare/models/scan_result.dart';
import 'package:fabricare/screens/scan/scan_result_screen.dart';
import 'package:fabricare/screens/scan/scan_screen.dart';

void main() {
  testWidgets('guided scan requires front and offers garment history inputs',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScanScreen()));
    expect(find.text('front · Required'), findsOneWidget);
    expect(find.text('back · Optional, encouraged'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Analyze garment'), 300);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Analyze garment'))
            .onPressed,
        isNull);
    expect(find.text('Garment history'), findsOneWidget);
    expect(find.text('I know the purchase date'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result displays backend score and future damage labels',
      (tester) async {
    final result = ScanResult(
        id: '1',
        userId: '1',
        garmentName: 'Test',
        images: [],
        dateScanned: DateTime(2026),
        analysis: {
          'fabric_type': 'Future blend',
          'fabric_confidence': 88,
          'health_score': 70,
          'condition_rating': 'Backend grade',
          'damages': [
            {'type': 'Future damage', 'confidence': 85, 'severity': 'minor'}
          ],
        });
    await tester
        .pumpWidget(MaterialApp(home: ScanResultScreen(result: result)));
    expect(find.text('Future blend · 88% confidence'), findsOneWidget);
    expect(find.text('Future damage'), findsOneWidget);
    expect(find.textContaining('70/100 · Backend grade'), findsOneWidget);
  });
}
