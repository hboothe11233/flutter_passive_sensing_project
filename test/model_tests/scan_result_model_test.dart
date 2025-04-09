// test/scan_result_model_test.dart

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_passive_sensing_project/models/scan_result_model.dart';

// --- Fake Classes to Simulate BLE Scan Results ---

/// A simple fake implementation of BluetoothDevice that supplies the fields we need.
class FakeBluetoothDevice implements BluetoothDevice {
  final String _advName;
  final DeviceIdentifier _remoteId;

  FakeBluetoothDevice({required String advName, required String remoteId})
      : _advName = advName,
        _remoteId = DeviceIdentifier(remoteId);

  @override
  String get advName => _advName;

  @override
  DeviceIdentifier get remoteId => _remoteId;

  @override
  // Other members are not used in our tests.
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A simple fake implementation of ScanResult.
/// We only need to supply the device, rssi, advertisementData and timestamp.
class FakeScanResult implements ScanResult {
  @override
  final BluetoothDevice device;
  @override
  final int rssi;
  @override
  final AdvertisementData advertisementData;
  @override
  final DateTime timestamp;

  FakeScanResult({
    required this.device,
    required this.rssi,
    required this.advertisementData,
    required this.timestamp,
  });

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Tests for ScanResultModel ---

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScanResultModel Serialization Tests', () {
    test('toJson and fromJson roundtrip', () {
      // Create a ScanResultModel instance.
      final model = ScanResultModel(
        deviceId: 'device123',
        deviceName: 'Test Device',
        rssi: -55,
      );

      // Convert to JSON.
      final jsonMap = model.toJson();
      expect(jsonMap['deviceId'], equals('device123'));
      expect(jsonMap['deviceName'], equals('Test Device'));
      expect(jsonMap['rssi'], equals(-55));

      // Convert back from JSON.
      final jsonString = jsonEncode(jsonMap);
      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final modelFromJson = ScanResultModel.fromJson(decodedMap);

      expect(modelFromJson.deviceId, equals('device123'));
      expect(modelFromJson.deviceName, equals('Test Device'));
      expect(modelFromJson.rssi, equals(-55));
    });

    test('fromScanResult uses provided advName', () {
      // Create a fake device with a non-empty advertised name.
      final fakeDevice = FakeBluetoothDevice(
        advName: 'Fake Device',
        remoteId: 'deviceABC',
      );

      // Create a fake advertisement data.
      final fakeAdvData = AdvertisementData( advName: 'Fake Device', txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {}, serviceData: {}, serviceUuids: []);

      // Create a fake scan result.
      final fakeScanResult = FakeScanResult(
        device: fakeDevice,
        rssi: -60,
        advertisementData: fakeAdvData,
        timestamp: DateTime.now(),
      );

      // Use the factory constructor.
      final model = ScanResultModel.fromScanResult(fakeScanResult);

      expect(model.deviceId, equals('deviceABC'));
      expect(model.deviceName, equals('Fake Device'));
      expect(model.rssi, equals(-60));
    });

    test('fromScanResult defaults to "Unknown" when advName is empty', () {
      // Create a fake device with an empty advertised name.
      final fakeDevice = FakeBluetoothDevice(
        advName: '',
        remoteId: 'deviceXYZ',
      );

      // Even if the AdvertisementData has a localName,
      // our factory uses result.device.advName and defaults to "Unknown" if empty.
      final fakeAdvData = AdvertisementData( advName: 'Fake Device', txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {}, serviceData: {}, serviceUuids: []);

      final fakeScanResult = FakeScanResult(
        device: fakeDevice,
        rssi: -70,
        advertisementData: fakeAdvData,
        timestamp: DateTime.now(),
      );

      final model = ScanResultModel.fromScanResult(fakeScanResult);
      expect(model.deviceId, equals('deviceXYZ'));
      // Expect "Unknown" because the advName was empty.
      expect(model.deviceName, equals('Unknown'));
      expect(model.rssi, equals(-70));
    });
  });
}
