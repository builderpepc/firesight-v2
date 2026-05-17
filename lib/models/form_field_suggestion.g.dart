// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_field_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormFieldSuggestion _$FormFieldSuggestionFromJson(Map<String, dynamic> json) =>
    FormFieldSuggestion(
      fieldId: json['field_id'] as String,
      value: json['value'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      source: $enumDecode(_$AutofillSourceEnumMap, json['source']),
      createdAt: DateTime.parse(json['created_at'] as String),
      evidence: json['evidence'] as String?,
    );

Map<String, dynamic> _$FormFieldSuggestionToJson(
        FormFieldSuggestion instance) =>
    <String, dynamic>{
      'field_id': instance.fieldId,
      'value': instance.value,
      'confidence': instance.confidence,
      'evidence': instance.evidence,
      'source': _$AutofillSourceEnumMap[instance.source]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$AutofillSourceEnumMap = {
  AutofillSource.ruleBased: 'rule_based',
  AutofillSource.cactus: 'cactus',
  AutofillSource.gemini: 'gemini',
  AutofillSource.userEdited: 'user_edited',
};
