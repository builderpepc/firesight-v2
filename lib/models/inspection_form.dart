import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inspection_form.g.dart';

/// Structured FireSight inspection form generated from observations.
@JsonSerializable()
class InspectionForm extends Equatable {
  const InspectionForm({
    this.buildingName,
    this.address,
    this.occupancyType,
    this.constructionType,
    this.alarmPanelLocation,
    this.sprinklerRiserLocation,
    this.fireProtectionSystems,
    this.utilityShutoffs,
    this.hazards,
    this.accessNotes,
    this.notes,
  });

  @JsonKey(name: 'building_name')
  final String? buildingName;

  final String? address;

  @JsonKey(name: 'occupancy_type')
  final String? occupancyType;

  @JsonKey(name: 'construction_type')
  final String? constructionType;

  @JsonKey(name: 'alarm_panel_location')
  final String? alarmPanelLocation;

  @JsonKey(name: 'sprinkler_riser_location')
  final String? sprinklerRiserLocation;

  @JsonKey(name: 'fire_protection_systems')
  final String? fireProtectionSystems;

  @JsonKey(name: 'utility_shutoffs')
  final String? utilityShutoffs;

  final String? hazards;

  @JsonKey(name: 'access_notes')
  final String? accessNotes;

  final String? notes;

  InspectionForm copyWith({
    String? buildingName,
    String? address,
    String? occupancyType,
    String? constructionType,
    String? alarmPanelLocation,
    String? sprinklerRiserLocation,
    String? fireProtectionSystems,
    String? utilityShutoffs,
    String? hazards,
    String? accessNotes,
    String? notes,
  }) {
    return InspectionForm(
      buildingName: buildingName ?? this.buildingName,
      address: address ?? this.address,
      occupancyType: occupancyType ?? this.occupancyType,
      constructionType: constructionType ?? this.constructionType,
      alarmPanelLocation: alarmPanelLocation ?? this.alarmPanelLocation,
      sprinklerRiserLocation:
          sprinklerRiserLocation ?? this.sprinklerRiserLocation,
      fireProtectionSystems:
          fireProtectionSystems ?? this.fireProtectionSystems,
      utilityShutoffs: utilityShutoffs ?? this.utilityShutoffs,
      hazards: hazards ?? this.hazards,
      accessNotes: accessNotes ?? this.accessNotes,
      notes: notes ?? this.notes,
    );
  }

  String? valueFor(String fieldId) {
    return switch (fieldId) {
      InspectionFormFieldIds.buildingName => buildingName,
      InspectionFormFieldIds.address => address,
      InspectionFormFieldIds.occupancyType => occupancyType,
      InspectionFormFieldIds.constructionType => constructionType,
      InspectionFormFieldIds.alarmPanelLocation => alarmPanelLocation,
      InspectionFormFieldIds.sprinklerRiserLocation => sprinklerRiserLocation,
      InspectionFormFieldIds.fireProtectionSystems => fireProtectionSystems,
      InspectionFormFieldIds.utilityShutoffs => utilityShutoffs,
      InspectionFormFieldIds.hazards => hazards,
      InspectionFormFieldIds.accessNotes => accessNotes,
      InspectionFormFieldIds.notes => notes,
      _ => null,
    };
  }

  InspectionForm applyFieldValue(String fieldId, String value) {
    return switch (fieldId) {
      InspectionFormFieldIds.buildingName => copyWith(buildingName: value),
      InspectionFormFieldIds.address => copyWith(address: value),
      InspectionFormFieldIds.occupancyType => copyWith(occupancyType: value),
      InspectionFormFieldIds.constructionType =>
        copyWith(constructionType: value),
      InspectionFormFieldIds.alarmPanelLocation =>
        copyWith(alarmPanelLocation: value),
      InspectionFormFieldIds.sprinklerRiserLocation =>
        copyWith(sprinklerRiserLocation: value),
      InspectionFormFieldIds.fireProtectionSystems =>
        copyWith(fireProtectionSystems: value),
      InspectionFormFieldIds.utilityShutoffs =>
        copyWith(utilityShutoffs: value),
      InspectionFormFieldIds.hazards => copyWith(hazards: value),
      InspectionFormFieldIds.accessNotes => copyWith(accessNotes: value),
      InspectionFormFieldIds.notes => copyWith(notes: value),
      _ => this,
    };
  }

  factory InspectionForm.fromJson(Map<String, dynamic> json) =>
      _$InspectionFormFromJson(json);

  Map<String, dynamic> toJson() => _$InspectionFormToJson(this);

  @override
  List<Object?> get props => [
        buildingName,
        address,
        occupancyType,
        constructionType,
        alarmPanelLocation,
        sprinklerRiserLocation,
        fireProtectionSystems,
        utilityShutoffs,
        hazards,
        accessNotes,
        notes,
      ];
}

/// Stable field IDs used by autofill engines, UI, and PDF generation.
class InspectionFormFieldIds {
  InspectionFormFieldIds._();

  static const buildingName = 'building_name';
  static const address = 'address';
  static const occupancyType = 'occupancy_type';
  static const constructionType = 'construction_type';
  static const alarmPanelLocation = 'alarm_panel_location';
  static const sprinklerRiserLocation = 'sprinkler_riser_location';
  static const fireProtectionSystems = 'fire_protection_systems';
  static const utilityShutoffs = 'utility_shutoffs';
  static const hazards = 'hazards';
  static const accessNotes = 'access_notes';
  static const notes = 'notes';
}
