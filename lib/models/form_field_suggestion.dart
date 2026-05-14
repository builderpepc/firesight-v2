import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'form_field_suggestion.g.dart';

enum AutofillSource {
  @JsonValue('rule_based')
  ruleBased,
  cactus,
  gemini,
  @JsonValue('user_edited')
  userEdited,
}

/// A proposed value for a single form field, including provenance.
@JsonSerializable()
class FormFieldSuggestion extends Equatable {
  const FormFieldSuggestion({
    required this.fieldId,
    required this.value,
    required this.confidence,
    required this.source,
    required this.createdAt,
    this.evidence,
  });

  @JsonKey(name: 'field_id')
  final String fieldId;

  final String value;
  final double confidence;
  final String? evidence;
  final AutofillSource source;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  factory FormFieldSuggestion.fromJson(Map<String, dynamic> json) =>
      _$FormFieldSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$FormFieldSuggestionToJson(this);

  @override
  List<Object?> get props => [
        fieldId,
        value,
        confidence,
        evidence,
        source,
        createdAt,
      ];
}
