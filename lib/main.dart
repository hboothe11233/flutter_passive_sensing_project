import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:workmanager/workmanager.dart';

/// Unique name for our background task.
const String scanTask = "backgroundBluetoothScanTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == scanTask) {
      debugPrint("Executing background Bluetooth scan task");

      // Start scanning with a fixed 5-second timeout.
      FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

      // Listen for scan results.
      List<ScanResult> results = [];
      var subscription = FlutterBluePlus.scanResults.listen((scanResults) {
        results = scanResults;
      });

      // Wait for the scan duration to complete.
      await Future.delayed(Duration(seconds: 5));
      FlutterBluePlus.stopScan();
      subscription.cancel();

      // Process the scan results (avoid duplicate devices).
      Set<String> deviceIds = {};
      int sumRssi = 0;
      int count = 0;
      for (var result in results) {
        if (!deviceIds.contains(result.device.remoteId.str)) {
          deviceIds.add(result.device.remoteId.str);
          count++;
          sumRssi += result.rssi;
        }
      }
      double avgRssi = count > 0 ? sumRssi / count : 0;

      debugPrint("Background scan completed: count = $count, avg RSSI = $avgRssi");
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager.
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Register a periodic background task.
  Workmanager().registerPeriodicTask(
    "1", // Unique name for this task.
    scanTask,
    frequency: Duration(minutes: 15),
  );

  runApp(MyApp());
}

/// Main app widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Scanner with Workmanager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

/// New model storing the raw results for each scan with timestamp.
class ScanBatch {
  final DateTime timestamp;
  final List<ScanResult> results;
  ScanBatch({
    required this.timestamp,
    required this.results,
  });
}

/// HomePage handles Bluetooth scanning in the foreground, data collection, filtering, and charting.
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // Store each scan’s raw batch.
  List<ScanBatch> _scanBatches = [];
  // Latest scan results for list view.
  List<ScanResult> devices = [];
  Timer? _timer;
  PermissionStatus permissions = PermissionStatus.denied;

  // Controller for filtering, its FocusNode, and a flag to control its visibility.
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";
  bool _showSearch = false;

  // ScrollController for jumping to the top when search is enabled.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((granted) {
      if (!mounted) return;
      if (granted) {
        debugPrint("Permissions granted. Starting foreground scan.");
        _performScan();
        // Schedule a foreground scan every 10 seconds.
        _timer = Timer.periodic(Duration(seconds: 10), (timer) {
          _performScan();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Required permissions not granted.')),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    FlutterBluePlus.stopScan();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Request necessary permissions.
  Future<bool> _checkPermissions() async {
    if (Platform.isIOS) {
      // // Request Bluetooth scanning permission for iOS.
      debugPrint("Requesting bluetooth permission");
      // await Permission.bluetooth.request();
      debugPrint("Requesting locations permission");
      // try {
        await Permission.bluetooth.request().then((bluetoothReponse) async {
          if(bluetoothReponse.isGranted){
            await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;
            permissions = await Permission.location.request();
          }
        });
      // } catch (e) {
      //   debugPrint(e.toString());
      // }
      // debugPrint("both responses: $bothResponses");
      return permissions.isGranted;
    } else {
      var locationStatus = await Permission.location.request();
      await Permission.backgroundRefresh.request();
      return locationStatus.isGranted;
    }
  }

  /// Perform a Bluetooth scan and store raw results as a ScanBatch.
  Future<void> _performScan() async {
    List<ScanResult> results = [];
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    var subscription = FlutterBluePlus.scanResults.listen((scanResults) {
      results = scanResults;
    });
    await Future.delayed(Duration(seconds: 5));
    FlutterBluePlus.stopScan();
    subscription.cancel();

    setState(() {
      devices = results;
      _scanBatches.add(ScanBatch(timestamp: DateTime.now(), results: results));
    });
  }

  /// Build a simple line chart using fl_chart.
  Widget _buildLineChart(List<FlSpot> spots, String title, String yAxisLabel) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.0),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      dotData: FlDotData(show: true),
                      barWidth: 3,
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build chart data for "Number of Devices" over time.
  List<FlSpot> _getDeviceCountSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _scanBatches.length; i++) {
      // Compute count based on filter.
      List<ScanResult> batchResults = _scanBatches[i].results;
      if (_searchQuery.isNotEmpty) {
        double? queryRssi = double.tryParse(_searchQuery);
        if (queryRssi != null) {
          batchResults = batchResults.where((result) => result.rssi <= queryRssi).toList();
        } else {
          batchResults = batchResults.where((result) {
            String deviceName = result.device.advName.isNotEmpty
                ? result.device.advName
                : result.device.remoteId.str;
            return deviceName.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }
      }
      int count = batchResults.length;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    return spots;
  }

  /// Build chart data for "Average RSSI" over time.
  List<FlSpot> _getAvgRssiSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _scanBatches.length; i++) {
      List<ScanResult> batchResults = _scanBatches[i].results;
      if (_searchQuery.isNotEmpty) {
        double? queryRssi = double.tryParse(_searchQuery);
        if (queryRssi != null) {
          batchResults = batchResults.where((result) => result.rssi <= queryRssi).toList();
        } else {
          batchResults = batchResults.where((result) {
            String deviceName = result.device.advName.isNotEmpty
                ? result.device.advName
                : result.device.remoteId.str;
            return deviceName.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }
      }
      int count = batchResults.length;
      int sumRssi = batchResults.fold(0, (prev, element) => prev + element.rssi);
      double avgRssi = count > 0 ? sumRssi / count : 0;
      spots.add(FlSpot(i.toDouble(), avgRssi));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    // Filter devices for list view.
    final filteredDevices = devices.where((device) {
      if (_searchQuery.isEmpty) return true;
      double? queryRssi = double.tryParse(_searchQuery);
      if (queryRssi != null) {
        return device.rssi <= queryRssi;
      } else {
        String deviceName = device.device.advName.isNotEmpty
            ? device.device.advName
            : device.device.remoteId.str;
        return deviceName.toLowerCase().contains(_searchQuery.toLowerCase());
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Scanner with Workmanager'),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Conditionally display the search field.
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  focusNode: _searchFocusNode,
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Filter by device name or min RSSI',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = "";
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            // Heading for detected devices.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Detected Bluetooth Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            filteredDevices.isEmpty
                ? Center(child: Text('No devices detected.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredDevices.length,
              itemBuilder: (context, index) {
                final result = filteredDevices[index];
                return ListTile(
                  title: Text(result.device.advName.isNotEmpty
                      ? result.device.advName
                      : "Unknown Device"),
                  subtitle: Text('ID: ${result.device.remoteId.str}'),
                  trailing: Text('RSSI: ${result.rssi}'),
                );
              },
            ),
            Divider(),
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Bluetooth Data Over Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 8.0),
            _buildLineChart(_getDeviceCountSpots(), 'Number of Devices', 'Count'),
            SizedBox(height: 8.0),
            _buildLineChart(_getAvgRssiSpots(), 'Average Signal Strength (RSSI)', 'RSSI'),
          ],
        ),
      ),
      // FAB toggles search field visibility, scrolls to top, activates the keyboard,
      // and clears the filter if the search field is hidden.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final bool newShowState = !_showSearch;
          setState(() {
            _showSearch = newShowState;
          });
          if (newShowState) {
            _scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            Future.delayed(Duration(milliseconds: 350), () {
              FocusScope.of(context).requestFocus(_searchFocusNode);
            });
          } else {
            // Clear filter when search field is hidden.
            _searchController.clear();
            setState(() {
              _searchQuery = "";
            });
          }
        },
        child: Icon(_showSearch ? Icons.search_off : Icons.search),
      ),
    );
  }
}
