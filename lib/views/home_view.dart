import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../models/scan_batch.dart';
import '../models/scan_result_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  /// Builds a line chart widget.
  Widget _buildLineChart(List<FlSpot> spots, String title, String yAxisLabel) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
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

  /// Generates chart data for the number of devices over time.
  List<FlSpot> _getDeviceCountSpots(List<ScanBatch> batches, String query) {
    List<FlSpot> spots = [];
    for (int i = 0; i < batches.length; i++) {
      List<ScanResultModel> batchResults = batches[i].results;
      if (query.isNotEmpty) {
        double? queryRssi = double.tryParse(query);
        if (queryRssi != null) {
          batchResults = batchResults.where((r) => r.rssi <= queryRssi).toList();
        } else {
          batchResults = batchResults.where((r) =>
              r.deviceName.toLowerCase().contains(query.toLowerCase())).toList();
        }
      }
      int count = batchResults.length;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    return spots;
  }

  /// Generates chart data for average RSSI over time.
  List<FlSpot> _getAvgRssiSpots(List<ScanBatch> batches, String query) {
    List<FlSpot> spots = [];
    for (int i = 0; i < batches.length; i++) {
      double avgRssi = 0;
      List<ScanResultModel> batchResults = batches[i].results;
      if (query.isNotEmpty) {
        double? queryRssi = double.tryParse(query);
        if (queryRssi != null) {
          batchResults = batchResults.where((r) => r.rssi <= queryRssi).toList();
        } else {
          batchResults = batchResults.where((r) =>
              r.deviceName.toLowerCase().contains(query.toLowerCase())).toList();
        }
      }
      int count = batchResults.length;
      int sumRssi = batchResults.fold(0, (prev, r) => prev + r.rssi);
      avgRssi = count > 0 ? sumRssi / count : 0;
      spots.add(FlSpot(i.toDouble(), avgRssi));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeController>(context);
    final filteredDevices = controller.devices.where((device) {
      if (controller.searchQuery.isEmpty) return true;
      double? queryRssi = double.tryParse(controller.searchQuery);
      if (queryRssi != null) {
        return device.rssi <= queryRssi;
      } else {
        String deviceName = device.device.advName.isNotEmpty
            ? device.device.advName
            : device.device.remoteId.str;
        return deviceName.toLowerCase().contains(controller.searchQuery.toLowerCase());
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Bluetooth Scanner')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear All Results',
            onPressed: () async {
              await controller.clearResults();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: controller.scrollController,
        child: Column(
          children: [
            if (controller.showSearch)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  focusNode: controller.searchFocusNode,
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    labelText: 'Filter by device name or min RSSI',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.searchController.clear();
                        controller.searchQuery = "";
                        controller.notifyListeners();
                      },
                    ),
                  ),
                  onChanged: (value) {
                    controller.searchQuery = value;
                    controller.notifyListeners();
                  },
                ),
              ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Detected Bluetooth Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            filteredDevices.isEmpty
                ? const Center(child: Text('No devices detected.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
            const Divider(),
            const SizedBox(height: 16.0),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Bluetooth Data Over Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8.0),
            _buildLineChart(
                _getDeviceCountSpots(controller.scanBatches, controller.searchQuery),
                'Number of Devices',
                'Count'),
            const SizedBox(height: 8.0),
            _buildLineChart(
                _getAvgRssiSpots(controller.scanBatches, controller.searchQuery),
                'Average Signal Strength (RSSI)',
                'RSSI'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final bool newShowState = !controller.showSearch;
          controller.showSearch = newShowState;
          controller.notifyListeners();
          if (newShowState) {
            controller.scrollController.animateTo(0,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            Future.delayed(const Duration(milliseconds: 350), () {
              FocusScope.of(context).requestFocus(controller.searchFocusNode);
            });
          } else {
            controller.searchController.clear();
            controller.searchQuery = "";
            controller.notifyListeners();
          }
        },
        child: Icon(controller.showSearch ? Icons.search_off : Icons.search),
      ),
    );
  }
}
