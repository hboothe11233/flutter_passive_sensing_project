// test/scan_batch_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_passive_sensing_project/models/scan_batch.dart';
import 'package:flutter_passive_sensing_project/models/scan_result_model.dart';

void main() {
  group('ScanBatch Model Tests', () {
    test('Serialization and Deserialization Roundtrip', () {
      // Create a dummy timestamp.
      final now = DateTime.now();

      // Create dummy ScanResultModel instances.
      final model1 = ScanResultModel(
        deviceId: 'device1',
        deviceName: 'Test Device 1',
        rssi: -50,
      );
      final model2 = ScanResultModel(
        deviceId: 'device2',
        deviceName: 'Test Device 2',
        rssi: -60,
      );

      // Create a ScanBatch instance.
      final batch = ScanBatch(
        timestamp: now,
        results: [model1, model2],
      );

      // Serialize the batch to a JSON map.
      final jsonMap = batch.toJson();
      expect(jsonMap, isA<Map<String, dynamic>>());
      expect(jsonMap['timestamp'], equals(now.toIso8601String()));
      expect(jsonMap['results'], isA<List<dynamic>>());
      expect((jsonMap['results'] as List).length, equals(2));

      // Convert the map to a JSON string and back.
      final jsonString = jsonEncode(jsonMap);
      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;

      // Deserialize the JSON map back into a ScanBatch.
      final roundTripBatch = ScanBatch.fromJson(decodedMap);
      expect(roundTripBatch.timestamp.toIso8601String(), equals(now.toIso8601String()));
      expect(roundTripBatch.results.length, equals(2));
      expect(roundTripBatch.results[0].deviceId, equals('device1'));
      expect(roundTripBatch.results[0].deviceName, equals('Test Device 1'));
      expect(roundTripBatch.results[0].rssi, equals(-50));
      expect(roundTripBatch.results[1].deviceId, equals('device2'));
      expect(roundTripBatch.results[1].deviceName, equals('Test Device 2'));
      expect(roundTripBatch.results[1].rssi, equals(-60));
    });
  });
}
