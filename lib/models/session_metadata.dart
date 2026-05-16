import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'session_metadata.g.dart';

/// Lightweight header for session list (without loading full observations).
@JsonSerializable()
class SessionMetadata extends Equatable {
  const SessionMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.zipCode,
    this.buildingType,
    this.status,
    this.inspectorId,
    this.riskLevel,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  @JsonKey(name: 'zip_code')
  final String? zipCode;

  @JsonKey(name: 'building_type')
  final String? buildingType;

  final String? status;

  @JsonKey(name: 'inspector_id')
  final String? inspectorId;

  @JsonKey(name: 'risk_level')
  final String? riskLevel;

  factory SessionMetadata.fromJson(Map<String, dynamic> json) =>
      _$SessionMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$SessionMetadataToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        createdAt,
        updatedAt,
        zipCode,
        buildingType,
        status,
        inspectorId,
        riskLevel,
      ];
}
