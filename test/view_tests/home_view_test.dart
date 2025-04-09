// test/home_view_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_passive_sensing_project/controllers/home_controller.dart';
import 'package:flutter_passive_sensing_project/models/scan_batch.dart';
import 'package:flutter_passive_sensing_project/models/scan_result_model.dart';
import 'package:flutter_passive_sensing_project/views/home_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// --- Fake Classes to Simulate BLE Scan Results ---
class FakeBluetoothDevice implements BluetoothDevice {
  final String _advName;
  final String _remoteId;
  FakeBluetoothDevice({required String advName, required String remoteId})
      : _advName = advName,
        _remoteId = remoteId;

  @override
  String get advName => _advName;

  @override
  DeviceIdentifier get remoteId => DeviceIdentifier(_remoteId);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

// --- A Fake HomeController to simulate behavior ---
class FakeHomeController extends HomeController {
  // Expose _scanBatches directly for testing.
  List<ScanBatch> get scanBatchesTest => scanBatches;

  @override
  Future<void> performScan() async {
    // Instead of actually scanning, simulate a scan result with a fake device.
    final fakeDevice = FakeBluetoothDevice(
      advName: "Fake Device 1",
      remoteId: "fake1",
    );
    final fakeScanResult = FakeScanResult(
      device: fakeDevice,
      rssi: -50,
      advertisementData: AdvertisementData( advName: 'Fake Device 1', txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {}, serviceData: {}, serviceUuids: []),
      timestamp: DateTime.now(),
    );
    // Simulate a foreground scan by adding the fake result.
    devices = [fakeScanResult];
    final model = ScanResultModel.fromScanResult(fakeScanResult);
    final batch = ScanBatch(timestamp: DateTime.now(), results: [model]);
    scanBatches.add(batch);
    isScanning = false;
    // Instead of persisting, we do nothing in our fake.
    notifyListeners();
  }

  @override
  Future<void> clearResults() async {
    scanBatches.clear();
    devices.clear();
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeView Widget Tests', () {
    late FakeHomeController fakeController;

    setUp(() {
      fakeController = FakeHomeController();
      // Prepopulate with a fake scan batch.
      final fakeModel = ScanResultModel(
        deviceId: "fake1",
        deviceName: "Fake Device 1",
        rssi: -50,
      );
      final dummyBatch = ScanBatch(
        timestamp: DateTime.now(),
        results: [fakeModel],
      );
      fakeController.devices = [
        FakeScanResult(
          device: FakeBluetoothDevice(advName: "Fake Device 1", remoteId: "fake1"),
          rssi: -50,
          advertisementData: AdvertisementData( advName: 'Fake Device', txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {}, serviceData: {}, serviceUuids: []),
          timestamp: DateTime.now(),
        )
      ];
      fakeController.scanBatches.add(dummyBatch);
      fakeController.searchQuery = "";
      fakeController.showSearch = false;
    });

    testWidgets('HomeView builds correctly and shows device list', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<HomeController>.value(
          value: fakeController,
          child: MaterialApp(
            home: HomeView(),
          ),
        ),
      );

      // Check that the AppBar title is found.
      expect(find.text('Bluetooth Scanner'), findsOneWidget);

      // Check that the "Detected Bluetooth Devices" heading exists.
      expect(find.text('Detected Bluetooth Devices'), findsOneWidget);

      // Verify that the fake device is displayed.
      expect(find.text('Fake Device 1'), findsOneWidget);
    });

    testWidgets('Toggling search field via FAB', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<HomeController>.value(
          value: fakeController,
          child: MaterialApp(
            home: HomeView(),
          ),
        ),
      );

      // Initially, the search field should be hidden.
      expect(find.byType(TextField), findsNothing);

      // Tap the FAB to show the search field.
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // The search field should now be visible.
      expect(find.byType(TextField), findsOneWidget);

      // Tap the FAB again to hide the search field.
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Clear All Results button clears scan batches and devices', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<HomeController>.value(
          value: fakeController,
          child: MaterialApp(
            home: HomeView(),
          ),
        ),
      );

      // Ensure the fake device is visible.
      expect(find.text('Fake Device 1'), findsOneWidget);

      // Tap the clear results button in the AppBar.
      final clearButtonFinder = find.byIcon(Icons.delete);
      expect(clearButtonFinder, findsOneWidget);
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      // Verify that the device list is cleared.
      expect(find.text('No devices detected.'), findsOneWidget);

      // Also, the controller's device and scanBatches should be empty.
      expect(fakeController.devices, isEmpty);
      expect(fakeController.scanBatchesTest, isEmpty);
    });
  });
}
