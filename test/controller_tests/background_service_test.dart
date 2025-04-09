// background_service_test.dart

import 'dart:async';
import 'package:flutter_passive_sensing_project/controllers/background_scan_controller.dart';
import 'package:flutter_test/flutter_test.dart';

// Expose a helper function that encapsulates the Workmanager task logic.
Future<bool> handleBackgroundTask(String task, Map<String, dynamic>? inputData) async {
  if (task == scanTask) {
    // Create a BackgroundScanController and run executeBackgroundScan.
    BackgroundScanController controller = BackgroundScanController();
    await controller.executeBackgroundScan();
  }
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Background Service Tests', () {
    test('handleBackgroundTask returns true for a non-scan task', () async {
      // When a task other than scanTask is provided, the background code should skip scanning.
      final result = await handleBackgroundTask("dummyTask", null);
      expect(result, true);
    });

    test('handleBackgroundTask processes scanTask correctly', () async {
      // For the scanTask, we simply verify that the function returns true.
      // (Note: In a more comprehensive test you might inject a mock BackgroundScanController
      // to ensure executeBackgroundScan is called, but here we assume it completes without error.)
      final result = await handleBackgroundTask(scanTask, null);
      expect(result, true);
    });
  });
}
