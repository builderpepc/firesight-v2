// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_form.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InspectionForm _$InspectionFormFromJson(Map<String, dynamic> json) =>
    InspectionForm(
      buildingName: json['building_name'] as String?,
      address: json['address'] as String?,
      occupancyType: json['occupancy_type'] as String?,
      constructionType: json['construction_type'] as String?,
      alarmPanelLocation: json['alarm_panel_location'] as String?,
      sprinklerRiserLocation: json['sprinkler_riser_location'] as String?,
      fireProtectionSystems: json['fire_protection_systems'] as String?,
      utilityShutoffs: json['utility_shutoffs'] as String?,
      hazards: json['hazards'] as String?,
      accessNotes: json['access_notes'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$InspectionFormToJson(InspectionForm instance) =>
    <String, dynamic>{
      'building_name': instance.buildingName,
      'address': instance.address,
      'occupancy_type': instance.occupancyType,
      'construction_type': instance.constructionType,
      'alarm_panel_location': instance.alarmPanelLocation,
      'sprinkler_riser_location': instance.sprinklerRiserLocation,
      'fire_protection_systems': instance.fireProtectionSystems,
      'utility_shutoffs': instance.utilityShutoffs,
      'hazards': instance.hazards,
      'access_notes': instance.accessNotes,
      'notes': instance.notes,
    };
