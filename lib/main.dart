import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'controllers/background_scan_controller.dart';
import 'controllers/home_controller.dart';
import 'views/home_view.dart';
import 'controllers/background_service.dart'; // Contains callbackDispatcher & scanTask

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On Android, initialize and enable background execution.
  if (Platform.isAndroid) {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "BLE Scanner Running",
      notificationText: "Scanning for nearby Bluetooth devices in the background.",
      notificationImportance: AndroidNotificationImportance.normal,
      enableWifiLock: true,
    );
    bool hasBackgroundExecution = await FlutterBackground.initialize(
      androidConfig: androidConfig,
    );
    if (hasBackgroundExecution) {
      await FlutterBackground.enableBackgroundExecution();
    }
  }

  // Initialize Workmanager.
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Register a periodic background task (for testing interval, use short period).
  Workmanager().registerPeriodicTask(
    "1",
    scanTask,
    frequency: Duration(minutes: 15),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => HomeController()..init(),
      child: MyApp(),
    ),
  );
}

/// Main app widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Scanner with Workmanager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeView(),
    );
  }
}
