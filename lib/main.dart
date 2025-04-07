import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

/// Main app widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

/// A simple model to record scan data over time.
class ScanRecord {
  final DateTime timestamp;
  final int deviceCount;
  final double averageRssi;

  ScanRecord({
    required this.timestamp,
    required this.deviceCount,
    required this.averageRssi,
  });
}

/// HomePage handles Bluetooth scanning, data collection and charting.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // List of recent scan records.
  List<ScanRecord> scanRecords = [];
  // List of devices from the most recent scan.
  List<ScanResult> devices = [];
  Timer? _timer;
  PermissionStatus permissions = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions().then((granted) {
        if (!mounted) return;
        if (granted) {
          // Start an immediate scan.
          debugPrint("About to perform scan");
          _performScan();
          // Then schedule periodic scans every 10 seconds.
          _timer = Timer.periodic(Duration(seconds: 10), (timer) {
            _performScan();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission is required for scanning.')),
          );
        }
      });
    // });
  }



  @override
  void dispose() {
    _timer?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  /// Request location permissions (required for Bluetooth scanning on Android).
  Future<bool> _checkPermissions() async {
    if (Platform.isIOS) {
      // // Request Bluetooth scanning permission for iOS.
      debugPrint("Requesting bluetooth permission");
      // await Permission.bluetooth.request();
      debugPrint("Requesting locations permission");
      // permissions = await Permission.location.request() ;
      List<PermissionStatus> bothResponses = [];
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
      debugPrint("both responses: $bothResponses");
      return permissions.isGranted;
    } else {
      // Request location permission on Android.
      var locationStatus = await Permission.location.request();
      return locationStatus.isGranted;
    }
  }

  /// Perform a Bluetooth scan for a fixed duration, update device list and record scan data.
  Future<void> _performScan() async {
    // Clear any previous scan results.
    List<ScanResult> results = [];
    // Start scanning with a 5-second timeout.
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    // Listen for scan results.
    var subscription = FlutterBluePlus.scanResults.listen((scanResults) {
      results = scanResults;
    });

    // Wait for the scan to complete.
    await Future.delayed(Duration(seconds: 5));
    FlutterBluePlus.stopScan();
    subscription.cancel();

    // Process the results: avoid duplicate devices by using a Set.
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

    if (!mounted) return;
    setState(() {
      devices = results;
      scanRecords.add(ScanRecord(
        timestamp: DateTime.now(),
        deviceCount: count,
        averageRssi: avgRssi,
      ));
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
            SizedBox(height: 8.0), // Adding space between title and chart.
            Container(
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
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toStringAsFixed(0));
                        },
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

  /// Prepare chart data (FlSpot) for device count.
  List<FlSpot> _getDeviceCountSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < scanRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), scanRecords[i].deviceCount.toDouble()));
    }
    return spots;
  }

  /// Prepare chart data (FlSpot) for average RSSI.
  List<FlSpot> _getAvgRssiSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < scanRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), scanRecords[i].averageRssi));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Scanner'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display current scan devices
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Detected Bluetooth Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            devices.isEmpty
                ? Center(child: Text('No devices detected.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final result = devices[index];
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
            SizedBox(height: 16.0), // Use SizedBox for adding whitespace.
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
      // Floating action button to manually trigger a scan.
      floatingActionButton: FloatingActionButton(
        onPressed: _performScan,
        child: Icon(Icons.search),
      ),
    );
  }
}
