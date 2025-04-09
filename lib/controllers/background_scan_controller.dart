import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_batch.dart';
import '../models/scan_result_model.dart';

/// Unique name for our background task.
const String scanTask = "backgroundBluetoothScanTask";
/// Key used for storing all scan batches.
const String bgScanKey = "all_scan_batches";

class BackgroundScanController {
  /// Executes a background BLE scan for a fixed duration,
  /// converts results to serializable ScanResultModel objects,
  /// creates a ScanBatch, and saves it to persistent storage.
  Future<bool> executeBackgroundScan() async {
    debugPrint("Executing background Bluetooth scan task");

    // Start scanning with a fixed 5-second timeout.
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    // Listen for scan results.
    List<ScanResult> results = [];
    var subscription =
    FlutterBluePlus.scanResults.listen((scanResults) {
      results = scanResults;
    });

    // Wait for scan duration to complete.
    await Future.delayed(Duration(seconds: 5));
    FlutterBluePlus.stopScan();
    subscription.cancel();

    // Optionally log device advertisement names.
    for (var r in results) {
      debugPrint(r.device.advName);
    }

    // Convert scan results into serializable models.
    List<ScanResultModel> models =
    results.map((r) => ScanResultModel.fromScanResult(r)).toList();

    // Create a new ScanBatch with the current timestamp.
    ScanBatch newBatch = ScanBatch(timestamp: DateTime.now(), results: models);

    // Save the new batch persistently.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList(bgScanKey) ?? <String>[];
    stored.add(jsonEncode(newBatch.toJson()));
    await prefs.setStringList(bgScanKey, stored);

    debugPrint("Background scan stored with ${models.length} devices.");
    return true;
  }
}
