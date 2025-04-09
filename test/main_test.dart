// test/main_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_passive_sensing_project/controllers/home_controller.dart';
import 'package:flutter_passive_sensing_project/main.dart';
import 'package:flutter_passive_sensing_project/models/scan_batch.dart';
import 'package:flutter_passive_sensing_project/models/scan_result_model.dart';
import 'package:flutter_passive_sensing_project/views/home_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Main App Tests', () {
    late HomeController controller;

    setUp(() async {
      // Create a HomeController instance.
      controller = HomeController();
      // For testing, you may call init() to simulate loading stored data,
      // checking permissions, and performing an initial scan.
      // Note: In unit tests the scanning functionality may not produce actual results.
      await controller.init();
      // Allow time for async tasks (e.g. loading stored batches).
      await Future.delayed(Duration(milliseconds: 100));
    });

    testWidgets('MyApp builds with correct title and HomeView widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<HomeController>.value(
          value: controller,
          child: const MyApp(),
        ),
      );

      // Trigger any pending async operations.
      await tester.pumpAndSettle();

      // Verify that the MaterialApp title is set correctly.
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, equals('Bluetooth Scanner with Workmanager'));

      // Verify that the HomeView is in the widget tree.
      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets('HomeView displays device list and AppBar actions', (WidgetTester tester) async {
      // Prepopulate with dummy scan data.
      controller.devices = [
        // Create a fake scan result using minimal implementation.
        FakeScanResult(
          device: FakeBluetoothDevice(advName: "Test Device", remoteId: "test1"),
          rssi: -55,
          advertisementData: AdvertisementData( advName: 'Test Device', txPowerLevel: null, appearance: null, connectable: true, manufacturerData: {}, serviceData: {}, serviceUuids: []),
          timestamp: DateTime.now(),
        )
      ];
      controller.scanBatches.add(
        ScanBatch(
          timestamp: DateTime.now(),
          results: [
            // Create a dummy scan result model.
            FakeScanResultModel(
              deviceId: "test1",
              deviceName: "Test Device",
              rssi: -55,
            )
          ],
        ),
      );
      // Notify listeners so that the UI rebuilds.
      controller.notifyListeners();

      await tester.pumpWidget(
        ChangeNotifierProvider<HomeController>.value(
          value: controller,
          child: const MaterialApp(
            home: HomeView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the AppBar title exists.
      expect(find.text('Bluetooth Scanner'), findsOneWidget);
      // Verify that the clear results button (delete icon) is present.
      expect(find.byIcon(Icons.delete), findsOneWidget);
      // Verify that the dummy device ("Test Device") appears.
      expect(find.text('Test Device'), findsOneWidget);
    });
  });
}

/// Minimal fake implementations for the purpose of testing HomeView.
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

class FakeScanResultModel extends ScanResultModel {
  FakeScanResultModel({
    required String deviceId,
    required String deviceName,
    required int rssi,
  }) : super(deviceId: deviceId, deviceName: deviceName, rssi: rssi);
}
