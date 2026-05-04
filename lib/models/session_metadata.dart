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
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SessionMetadata.fromJson(Map<String, dynamic> json) =>
      _$SessionMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$SessionMetadataToJson(this);

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt];
}
