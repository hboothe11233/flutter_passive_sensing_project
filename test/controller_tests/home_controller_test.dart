// test/home_controller_test.dart

import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_passive_sensing_project/controllers/home_controller.dart';
import 'package:flutter_passive_sensing_project/models/scan_batch.dart';
import 'package:flutter_passive_sensing_project/models/scan_result_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Ensure test environment is initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeController Tests', () {
    setUp(() async {
      // Clear shared preferences before every test.
      SharedPreferences.setMockInitialValues({});
    });

    test('loadStoredBatches loads stored scan batches from SharedPreferences', () async {
      // Create a dummy scan batch.
      final testBatch = ScanBatch(
        timestamp: DateTime.now(),
        results: [
          ScanResultModel(deviceId: 'id1', deviceName: 'Device1', rssi: -50),
        ],
      );
      final jsonStr = jsonEncode(testBatch.toJson());
      // Set the mock shared preferences to contain one batch.
      SharedPreferences.setMockInitialValues({'all_scan_batches': [jsonStr]});

      final controller = HomeController();
      await controller.loadStoredBatches();

      expect(controller.scanBatches.length, equals(1));
      expect(controller.scanBatches.first.results.first.deviceId, equals('id1'));
    });

    test('clearResults clears in-memory scan batches and devices', () async {
      final controller = HomeController();

      // Prepopulate the controller with a dummy batch.
      final dummyBatch = ScanBatch(
        timestamp: DateTime.now(),
        results: [
          ScanResultModel(deviceId: 'id1', deviceName: 'Device1', rssi: -50)
        ],
      );
      controller.devices = [
        // Simulate a ScanResult (using a fake BluetoothDevice)
        ScanResult(
          device: BluetoothDevice(
            remoteId: DeviceIdentifier("id1"),
          ),
          rssi: -50,
          advertisementData: AdvertisementData( advName: 'Test Device', txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {}, serviceData: {}, serviceUuids: []),
          timeStamp: DateTime.now(),
        )
      ];
      controller.scanBatches.add(dummyBatch);

      // Clear results.
      await controller.clearResults();

      expect(controller.scanBatches, isEmpty);
      expect(controller.devices, isEmpty);
    });

    test('saveBatches persists current scan batches to SharedPreferences', () async {
      final controller = HomeController();
      // Add a dummy batch.
      final testBatch = ScanBatch(
        timestamp: DateTime.now(),
        results: [
          ScanResultModel(deviceId: 'id2', deviceName: 'Device2', rssi: -60),
        ],
      );
      controller.scanBatches.add(testBatch);

      await controller.saveBatches();

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('all_scan_batches');
      expect(stored, isNotNull);
      expect(stored!.length, equals(1));

      final decoded = jsonDecode(stored.first);
      final loadedBatch = ScanBatch.fromJson(decoded);
      expect(loadedBatch.results.first.deviceId, equals('id2'));
    });

    test('performScan adds a new batch and updates state', () async {
      // Set mock SharedPreferences to empty.
      SharedPreferences.setMockInitialValues({});

      final controller = HomeController();
      // For the purpose of this test, assume that in the test environment
      // no scan devices are discovered (i.e. an empty result list).
      // Call performScan to simulate a foreground scan.
      await controller.performScan();

      // After scanning, we expect a new batch to be added.
      expect(controller.scanBatches.length, greaterThanOrEqualTo(1));
      // Since no devices were discovered, devices list should be empty.
      expect(controller.devices.isEmpty, isTrue);
      expect(controller.isScanning, isFalse);
    });
  });
}
