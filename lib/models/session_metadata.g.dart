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
      zipCode: json['zip_code'] as String?,
      buildingType: json['building_type'] as String?,
      status: json['status'] as String?,
      inspectorId: json['inspector_id'] as String?,
      riskLevel: json['risk_level'] as String?,
    );

Map<String, dynamic> _$SessionMetadataToJson(SessionMetadata instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'zip_code': instance.zipCode,
      'building_type': instance.buildingType,
      'status': instance.status,
      'inspector_id': instance.inspectorId,
      'risk_level': instance.riskLevel,
    };
