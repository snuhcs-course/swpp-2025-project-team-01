// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppDataAdapter extends TypeAdapter<AppData> {
  @override
  final int typeId = 0;

  @override
  AppData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppData(
      settings: fields[0] as AppSettings?,
      subjects: (fields[1] as Map?)?.cast<String, HiveSubject>(),
      tags: (fields[2] as Map?)?.cast<String, HiveTag>(),
      lectures: (fields[4] as Map?)?.cast<String, HiveLecture>(),
      uiState: fields[3] as UiState?,
    );
  }

  @override
  void write(BinaryWriter writer, AppData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.settings)
      ..writeByte(1)
      ..write(obj.subjects)
      ..writeByte(2)
      ..write(obj.tags)
      ..writeByte(3)
      ..write(obj.uiState)
      ..writeByte(4)
      ..write(obj.lectures);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      theme: fields[0] as String,
      language: fields[1] as String,
      accessibilityHighContrast: fields[2] as bool,
      accessibilityReduceMotion: fields[3] as bool,
      accessibilityEmphasizeCaptions: fields[4] as bool,
      ttsGender: fields[5] as String,
      ttsSpeed: fields[6] as String,
      tagColorTheme: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.theme)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.accessibilityHighContrast)
      ..writeByte(3)
      ..write(obj.accessibilityReduceMotion)
      ..writeByte(4)
      ..write(obj.accessibilityEmphasizeCaptions)
      ..writeByte(5)
      ..write(obj.ttsGender)
      ..writeByte(6)
      ..write(obj.ttsSpeed)
      ..writeByte(7)
      ..write(obj.tagColorTheme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UiStateAdapter extends TypeAdapter<UiState> {
  @override
  final int typeId = 2;

  @override
  UiState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UiState(
      subjectExpandedStates: (fields[0] as Map?)?.cast<String, bool>(),
      recentSearches: (fields[1] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UiState obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.subjectExpandedStates)
      ..writeByte(1)
      ..write(obj.recentSearches);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSubjectAdapter extends TypeAdapter<HiveSubject> {
  @override
  final int typeId = 3;

  @override
  HiveSubject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSubject(
      id: fields[0] as String,
      title: fields[1] as String,
      favorite: fields[2] as bool,
      tagIds: (fields[3] as List?)?.cast<String>(),
      lectureIds: (fields[4] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveSubject obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.favorite)
      ..writeByte(3)
      ..write(obj.tagIds)
      ..writeByte(4)
      ..write(obj.lectureIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSubjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveTagAdapter extends TypeAdapter<HiveTag> {
  @override
  final int typeId = 4;

  @override
  HiveTag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveTag(
      id: fields[0] as String,
      name: fields[1] as String,
      color: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveTag obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.color);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveLectureAdapter extends TypeAdapter<HiveLecture> {
  @override
  final int typeId = 5;

  @override
  HiveLecture read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveLecture(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      weekLabel: fields[2] as String,
      title: fields[3] as String,
      durationSec: fields[4] as int,
      slidesUrl: fields[5] as String?,
      audioUrl: fields[6] as String?,
      thumbnailUrl: fields[7] as String?,
      transcriptUrl: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveLecture obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.weekLabel)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.durationSec)
      ..writeByte(5)
      ..write(obj.slidesUrl)
      ..writeByte(6)
      ..write(obj.audioUrl)
      ..writeByte(7)
      ..write(obj.thumbnailUrl)
      ..writeByte(8)
      ..write(obj.transcriptUrl)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveLectureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
