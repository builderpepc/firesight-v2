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

  BuildingDocument copyWith({
    String? id,
    String? fileName,
    String? filePath,
    DateTime? uploadedAt,
    String? preprocessedText,
  }) {
    return BuildingDocument(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      preprocessedText: preprocessedText ?? this.preprocessedText,
    );
  }

  @override
  List<Object?> get props => [id, fileName, filePath, uploadedAt, preprocessedText];
}
