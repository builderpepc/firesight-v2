// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InspectionSession _$InspectionSessionFromJson(Map<String, dynamic> json) =>
    InspectionSession(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      observations: (json['observations'] as List<dynamic>?)
              ?.map((e) => Observation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      buildingDocuments: (json['building_documents'] as List<dynamic>?)
              ?.map((e) => BuildingDocument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      floorplanPath: json['floorplan_path'] as String?,
    );

Map<String, dynamic> _$InspectionSessionToJson(InspectionSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'observations': instance.observations,
      'building_documents': instance.buildingDocuments,
      'floorplan_path': instance.floorplanPath,
    };
