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
  final String material;

  @HiveField(1)
  final bool recyclable;

  @HiveField(2)
  final String? recycledCarbonScore;

  @HiveField(3)
  final String? unrecycledCarbonScore;

  @HiveField(4)
  final String? carbonImpactRecycled;

  @HiveField(5)
  final String? carbonImpactUnrecycled;

  @HiveField(6)
  final double? recyclingrate;

  @HiveField(7)
  final bool hasSubtypes;

  @HiveField(8)
  final List<String> notes;

  ClassificationResult({
    required this.material,
    required this.recyclable,
    this.recycledCarbonScore,
    this.unrecycledCarbonScore,
    this.carbonImpactRecycled,
    this.carbonImpactUnrecycled,
    this.recyclingrate,
    required this.hasSubtypes,
    required this.notes,
  });
}
