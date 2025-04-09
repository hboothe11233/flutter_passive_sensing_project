import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// A serializable model representing a single scan result.
class ScanResultModel {
  final String deviceId;
  final String deviceName;
  final int rssi;

  ScanResultModel({
    required this.deviceId,
    required this.deviceName,
    required this.rssi,
  });

  factory ScanResultModel.fromScanResult(ScanResult result) {
    return ScanResultModel(
      deviceId: result.device.remoteId.str,
      deviceName: result.device.advName.isNotEmpty ? result.device.advName : "Unknown",
      rssi: result.rssi,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'deviceName': deviceName,
      'rssi': rssi,
    };
  }

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    final String? deviceId = json['deviceId'] as String?;
    final String? deviceName = json['deviceName'] as String?;
    final int? rssi = json['rssi'] as int?;

    if (deviceId == null) {
      throw Exception("Missing 'deviceId' in JSON");
    }
    if (deviceName == null) {
      throw Exception("Missing 'deviceName' in JSON");
    }
    if (rssi == null) {
      throw Exception("Missing 'rssi' in JSON");
    }

    return ScanResultModel(
      deviceId: deviceId,
      deviceName: deviceName,
      rssi: rssi,
    );
  }
}
