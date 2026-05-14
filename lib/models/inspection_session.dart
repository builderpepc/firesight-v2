import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'observation.dart';
import 'building_document.dart';
import 'form_field_suggestion.dart';
import 'inspection_form.dart';

part 'inspection_session.g.dart';

/// Represents a complete inspection session with observations.
@JsonSerializable()
class InspectionSession extends Equatable {
  const InspectionSession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.observations = const [],
    this.buildingDocuments = const [],
    this.floorplanPath,
    this.zipCode,
    this.buildingType,
    this.status,
    this.inspectorId,
    this.riskLevel,
    this.form = const InspectionForm(),
    this.formSuggestions = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  @JsonKey(name: 'observations')
  final List<Observation> observations;

  @JsonKey(name: 'building_documents')
  final List<BuildingDocument> buildingDocuments;

  @JsonKey(name: 'floorplan_path')
  final String? floorplanPath;

  @JsonKey(name: 'zip_code')
  final String? zipCode;

  @JsonKey(name: 'building_type')
  final String? buildingType;

  final String? status;

  @JsonKey(name: 'inspector_id')
  final String? inspectorId;

  @JsonKey(name: 'risk_level')
  final String? riskLevel;

  final InspectionForm form;

  @JsonKey(name: 'form_suggestions')
  final List<FormFieldSuggestion> formSuggestions;

  InspectionSession copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Observation>? observations,
    List<BuildingDocument>? buildingDocuments,
    String? floorplanPath,
    String? zipCode,
    String? buildingType,
    String? status,
    String? inspectorId,
    String? riskLevel,
    InspectionForm? form,
    List<FormFieldSuggestion>? formSuggestions,
  }) {
    return InspectionSession(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      observations: observations ?? this.observations,
      buildingDocuments: buildingDocuments ?? this.buildingDocuments,
      floorplanPath: floorplanPath ?? this.floorplanPath,
      zipCode: zipCode ?? this.zipCode,
      buildingType: buildingType ?? this.buildingType,
      status: status ?? this.status,
      inspectorId: inspectorId ?? this.inspectorId,
      riskLevel: riskLevel ?? this.riskLevel,
      form: form ?? this.form,
      formSuggestions: formSuggestions ?? this.formSuggestions,
    );
  }

  factory InspectionSession.fromJson(Map<String, dynamic> json) =>
      _$InspectionSessionFromJson(json);

  Map<String, dynamic> toJson() => _$InspectionSessionToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        createdAt,
        updatedAt,
        observations,
        buildingDocuments,
        floorplanPath,
        zipCode,
        buildingType,
        status,
        inspectorId,
        riskLevel,
        form,
        formSuggestions,
      ];
}
