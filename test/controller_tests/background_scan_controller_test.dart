import 'dart:convert';
import 'package:flutter_passive_sensing_project/controllers/background_scan_controller.dart';
import 'package:flutter_passive_sensing_project/models/scan_batch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundScanController Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test.
      SharedPreferences.setMockInitialValues({});
    });

    test('executeBackgroundScan stores an empty batch when no scan results are present', () async {
      // In a test environment, if no devices are discovered,
      // FlutterBluePlus.scanResults will return an empty list.

      // Create an instance of the controller.
      final controller = BackgroundScanController();

      // Execute the background scan.
      final result = await controller.executeBackgroundScan();
      expect(result, true);

      // Verify that a batch was stored in SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('all_scan_batches');
      expect(stored, isNotNull);
      expect(stored!.length, equals(1));

      // Parse the stored batch.
      final batchMap = jsonDecode(stored.first);
      final batch = ScanBatch.fromJson(batchMap);
      // Since no scan results were produced, expect an empty list.
      expect(batch.results.length, equals(0));
    });
  });
}
