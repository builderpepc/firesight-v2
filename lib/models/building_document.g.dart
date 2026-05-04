// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildingDocument _$BuildingDocumentFromJson(Map<String, dynamic> json) =>
    BuildingDocument(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      preprocessedText: json['preprocessed_text'] as String?,
    );

Map<String, dynamic> _$BuildingDocumentToJson(BuildingDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'filePath': instance.filePath,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
      'preprocessed_text': instance.preprocessedText,
    };
