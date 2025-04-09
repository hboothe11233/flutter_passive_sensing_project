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
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'rssi': rssi,
    };
  }

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      rssi: json['rssi'],
    );
  }
}