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
      zipCode: json['zip_code'] as String?,
      buildingType: json['building_type'] as String?,
      status: json['status'] as String?,
      inspectorId: json['inspector_id'] as String?,
      riskLevel: json['risk_level'] as String?,
      form: json['form'] == null
          ? const InspectionForm()
          : InspectionForm.fromJson(json['form'] as Map<String, dynamic>),
      formSuggestions: (json['form_suggestions'] as List<dynamic>?)
              ?.map((e) =>
                  FormFieldSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$InspectionSessionToJson(InspectionSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'observations': instance.observations.map((e) => e.toJson()).toList(),
      'building_documents':
          instance.buildingDocuments.map((e) => e.toJson()).toList(),
      'floorplan_path': instance.floorplanPath,
      'zip_code': instance.zipCode,
      'building_type': instance.buildingType,
      'status': instance.status,
      'inspector_id': instance.inspectorId,
      'risk_level': instance.riskLevel,
      'form': instance.form.toJson(),
      'form_suggestions':
          instance.formSuggestions.map((e) => e.toJson()).toList(),
    };
