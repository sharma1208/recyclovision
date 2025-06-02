import 'package:hive/hive.dart';

part 'scan_record.g.dart';

@HiveType(typeId: 0)
class ScanRecord {
  @HiveField(0)
  final String imagePath;

  @HiveField(1)
  final ClassificationResult classificationResult;

  @HiveField(2)
  final DateTime timestamp;

  ScanRecord({
    required this.imagePath,
    required this.classificationResult,
    required this.timestamp,
  });
}

@HiveType(typeId: 1)
class ClassificationResult {
  @HiveField(0)
  final String className;

  @HiveField(1)
  final String material;

  @HiveField(2)
  final bool recyclable;

  @HiveField(3)
  final String carbonScore;

  // You can add more fields here if you want to store confidence, bounding boxes, etc.

  ClassificationResult({
    required this.className,
    required this.material,
    required this.recyclable,
    required this.carbonScore,
  });
}
