// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_preview.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaPreviewAdapter extends TypeAdapter<MediaPreview> {
  @override
  final int typeId = 0;

  @override
  MediaPreview read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaPreview(
      id: fields[0] as int,
      title: fields[1] as String,
      date: fields[2] as String,
      poster: fields[3] as String,
      overview: fields[4] as String,
      trailerKey: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MediaPreview obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.poster)
      ..writeByte(4)
      ..write(obj.overview)
      ..writeByte(5)
      ..write(obj.trailerKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaPreviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
