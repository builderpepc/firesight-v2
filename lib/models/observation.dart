import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'observation.g.dart';

/// Represents a single voice observation with optional photo reference.
@JsonSerializable()
class Observation extends Equatable {
  const Observation({
    required this.id,
    required this.timestamp,
    this.text,
    this.photoFileRef,
    this.response,
  });

  final String id;
  final DateTime timestamp;
  final String? text;

  @JsonKey(name: 'photo_file_ref')
  final String? photoFileRef;

  final String? response;

  factory Observation.fromJson(Map<String, dynamic> json) =>
      _$ObservationFromJson(json);

  Map<String, dynamic> toJson() => _$ObservationToJson(this);

  @override
  List<Object?> get props => [id, timestamp, text, photoFileRef, response];
}
