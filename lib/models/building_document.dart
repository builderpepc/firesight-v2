import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'building_document.g.dart';

/// Represents an uploaded building document with preprocessed text.
@JsonSerializable()
class BuildingDocument extends Equatable {
  const BuildingDocument({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.uploadedAt,
    this.preprocessedText,
  });

  final String id;
  final String fileName;
  final String filePath;
  final DateTime uploadedAt;

  @JsonKey(name: 'preprocessed_text')
  final String? preprocessedText;

  factory BuildingDocument.fromJson(Map<String, dynamic> json) =>
      _$BuildingDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$BuildingDocumentToJson(this);

  @override
  List<Object?> get props => [id, fileName, filePath, uploadedAt, preprocessedText];
}
