// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionMetadata _$SessionMetadataFromJson(Map<String, dynamic> json) =>
    SessionMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SessionMetadataToJson(SessionMetadata instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
