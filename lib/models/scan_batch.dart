// scan_batch.dart
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
    return <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
      'results': results.map((ScanResultModel r) => r.toJson()).toList(),
    };
  }

  factory ScanBatch.fromJson(Map<String, dynamic> json) {
    final String? timestampStr = json['timestamp'] as String?;
    final List<dynamic>? resultsList = json['results'] as List<dynamic>?;

    if (timestampStr == null) {
      throw Exception("Missing 'timestamp' in JSON");
    }
    if (resultsList == null) {
      throw Exception("Missing 'results' in JSON");
    }

    return ScanBatch(
      timestamp: DateTime.parse(timestampStr),
      results: resultsList
          .map((dynamic r) => ScanResultModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
