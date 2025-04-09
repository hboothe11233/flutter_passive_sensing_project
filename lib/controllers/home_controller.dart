import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_batch.dart';
import '../models/scan_result_model.dart';

class HomeController extends ChangeNotifier {
  // In-memory list of all scan batches.
  final List<ScanBatch> _scanBatches = [];
  List<ScanBatch> get scanBatches => _scanBatches;

  // Latest foreground scan results.
  List<ScanResult> devices = [];
  bool isScanning = false;
  Timer? timer;
  PermissionStatus permissions = PermissionStatus.denied;

  // Controllers for search.
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // Search UI state.
  String searchQuery = "";
  bool showSearch = false;

  // Scroll controller to allow scrolling the view.
  final ScrollController scrollController = ScrollController();

  /// Loads scan batches from persistent storage.
  Future<void> loadStoredBatches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList('all_scan_batches') ?? [];
    List<ScanBatch> storedBatches = stored
        .map((str) => ScanBatch.fromJson(jsonDecode(str)))
        .toList();
    await prefs.remove('all_scan_batches');
    _scanBatches.addAll(storedBatches);
    _scanBatches.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();
  }

  /// Persists the current scan batches list.
  Future<void> saveBatches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> toStore =
    _scanBatches.map((batch) => jsonEncode(batch.toJson())).toList();
    await prefs.setStringList('all_scan_batches', toStore);
  }

  /// Clears all scan results from memory and persistent storage.
  Future<void> clearResults() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('all_scan_batches');
    _scanBatches.clear();
    devices.clear();
    notifyListeners();
  }

  /// Checks necessary permissions.
  Future<bool> checkPermissions() async {
    if (Platform.isIOS) {
      await Permission.bluetooth.request();
      permissions = await Permission.location.request();
      return permissions.isGranted;
    } else {
      var locationStatus = await Permission.location.request();
      await Permission.backgroundRefresh.request();
      return locationStatus.isGranted;
    }
  }

  /// Performs a foreground scan and saves the result.
  Future<void> performScan() async {
    if (isScanning) return;
    isScanning = true;
    notifyListeners();

    List<ScanResult> results = [];
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    var subscription = FlutterBluePlus.scanResults.listen((scanResults) {
      results = scanResults;
    });
    await Future.delayed(Duration(seconds: 5));
    FlutterBluePlus.stopScan();
    subscription.cancel();

    List<ScanResultModel> models =
    results.map((r) => ScanResultModel.fromScanResult(r)).toList();
    ScanBatch newBatch = ScanBatch(timestamp: DateTime.now(), results: models);

    devices = results;
    _scanBatches.add(newBatch);
    isScanning = false;
    await saveBatches();
    notifyListeners();
  }

  /// Initializes the controller.
  Future<void> init() async {
    await loadStoredBatches();
    bool granted = await checkPermissions();
    if (granted) {
      await performScan();
      timer = Timer.periodic(Duration(seconds: 10), (t) async {
        await performScan();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
