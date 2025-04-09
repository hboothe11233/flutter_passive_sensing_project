import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'background_scan_controller.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  // Ensure the widgets binding is initialized in the background isolate.
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().executeTask((task, inputData) async {
    if (task == scanTask) {
      BackgroundScanController controller = BackgroundScanController();
      await controller.executeBackgroundScan();
    }
    return Future.value(true);
  });
}
