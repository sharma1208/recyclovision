// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanRecordAdapter extends TypeAdapter<ScanRecord> {
  @override
  final int typeId = 0;

  @override
  ScanRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanRecord(
      imagePath: fields[0] as String,
      classificationResult: fields[1] as ClassificationResult,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScanRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.classificationResult)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClassificationResultAdapter extends TypeAdapter<ClassificationResult> {
  @override
  final int typeId = 1;

  @override
  ClassificationResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassificationResult(
      className: fields[0] as String,
      material: fields[1] as String,
      recyclable: fields[2] as bool,
      carbonScore: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ClassificationResult obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.className)
      ..writeByte(1)
      ..write(obj.material)
      ..writeByte(2)
      ..write(obj.recyclable)
      ..writeByte(3)
      ..write(obj.carbonScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassificationResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
