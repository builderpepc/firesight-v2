// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Observation _$ObservationFromJson(Map<String, dynamic> json) => Observation(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      text: json['text'] as String?,
      photoFileRef: json['photo_file_ref'] as String?,
      response: json['response'] as String?,
      floorplanX: (json['floorplan_x'] as num?)?.toDouble(),
      floorplanY: (json['floorplan_y'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ObservationToJson(Observation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'text': instance.text,
      'photo_file_ref': instance.photoFileRef,
      'response': instance.response,
      'floorplan_x': instance.floorplanX,
      'floorplan_y': instance.floorplanY,
    };
