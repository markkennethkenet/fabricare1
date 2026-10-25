import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fabricare/models/scan_result.dart';
import 'package:fabricare/services/history_store.dart';

void main() {
  test(
      'history survives reopen, keeps every detection, and scopes delete/clear by account',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('fabricare_history_test');
    final source = File('${directory.path}/source.jpg');
    await source.writeAsBytes([1, 2, 3]);
    final store = HistoryStore(Directory('${directory.path}/store'));
    await store.open();
    ScanResult scan(String id, String userId) => ScanResult(
        id: id,
        userId: userId,
        garmentName: 'Test garment',
        images: [ScanImage(view: 'front', path: source.path)],
        dateScanned: DateTime(2026, 10, 20),
        userInputs: const {'condition': 'new'},
        analysis: {
          'fabric_type': 'future_fabric',
          'fabric_confidence': 91,
          'health_score': 70,
          'condition_rating': 'Fair',
          'estimated_remaining_months': 12,
          'damages': [
            for (var i = 0; i < 2; i++)
              {
                'id': '0:$i',
                'type': 'future_damage',
                'confidence': 85,
                'severity': 'minor',
                'bbox': [.1, .2, .1, .1],
                'area_ratio': .01,
                'image_index': 0,
                'view': 'front'
              }
          ]
        });
    final saved = await store.add(scan('1', '10'));
    await store.add(scan('2', '10'));
    await store.add(scan('3', '20'));
    expect(saved.image!.path, isNot(source.path));
    await store.close();
    final reopened = HistoryStore(Directory('${directory.path}/store'));
    await reopened.open();
    expect(reopened.forUser('10').length, 2);
    final restored = reopened.forUser('10').first;
    expect(restored.damageDetection.items.length, 2);
    expect(restored.userInputs['condition'], 'new');
    expect(restored.healthRating,
        'Fair'); // Display the API grade, do not recalculate.
    expect(await restored.image!.exists(), isTrue);
    await reopened.delete('10', '1');
    expect(await saved.image!.exists(), isFalse);
    await reopened.clear('10');
    expect(reopened.forUser('10'), isEmpty);
    expect(reopened.forUser('20').length, 1);
    await reopened.close();
    await directory.delete(recursive: true);
  });
}
