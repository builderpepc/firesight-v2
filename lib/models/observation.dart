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
    this.floorplanX,
    this.floorplanY,
    this.category,
  });

  final String id;
  final DateTime timestamp;
  final String? text;

  @JsonKey(name: 'photo_file_ref')
  final String? photoFileRef;

  final String? response;

  @JsonKey(name: 'floorplan_x')
  final double? floorplanX;

  @JsonKey(name: 'floorplan_y')
  final double? floorplanY;

  final String? category;

  factory Observation.fromJson(Map<String, dynamic> json) =>
      _$ObservationFromJson(json);

  Map<String, dynamic> toJson() => _$ObservationToJson(this);

  Observation copyWith({
    String? id,
    DateTime? timestamp,
    String? text,
    String? photoFileRef,
    String? response,
    double? floorplanX,
    double? floorplanY,
    String? category,
  }) {
    return Observation(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      photoFileRef: photoFileRef ?? this.photoFileRef,
      response: response ?? this.response,
      floorplanX: floorplanX ?? this.floorplanX,
      floorplanY: floorplanY ?? this.floorplanY,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        text,
        photoFileRef,
        response,
        floorplanX,
        floorplanY,
        category,
      ];
}
