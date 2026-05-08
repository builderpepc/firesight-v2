import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'observation.dart';
import 'building_document.dart';

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

  InspectionSession copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Observation>? observations,
    List<BuildingDocument>? buildingDocuments,
    String? floorplanPath,
  }) {
    return InspectionSession(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      observations: observations ?? this.observations,
      buildingDocuments: buildingDocuments ?? this.buildingDocuments,
      floorplanPath: floorplanPath ?? this.floorplanPath,
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
      ];
}
