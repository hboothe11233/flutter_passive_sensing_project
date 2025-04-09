// models.dart
import 'package:flutter_passive_sensing_project/models/scan_result_model.dart';

/// A model storing a batch of scan results with timestamp.
class ScanBatch {
  final DateTime timestamp;
  final List<ScanResultModel> results;

  ScanBatch({
    required this.timestamp,
    required this.results,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
    };
  }

  factory ScanBatch.fromJson(Map<String, dynamic> json) {
    return ScanBatch(
      timestamp: DateTime.parse(json['timestamp']),
      results: (json['results'] as List)
          .map((r) => ScanResultModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}