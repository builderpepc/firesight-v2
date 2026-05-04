// ignore_for_file: unused_field, unused_local_variable
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';

/// Converts uploaded docs (PDF/images) → Markdown via Gemini.
class DocumentPreprocessor {
  DocumentPreprocessor(this._model);

  final GenerativeModel _model;

  /// Processes a file and returns condensed Markdown text.
  Future<String> preprocess(File file) async {
    final bytes = await file.readAsBytes();
    final contentType = _getContentType(file.path);

    // TODO: Use firebase_ai multimodal (Gemini 2.5 Flash) to convert.
    // Pass file bytes and prompt to extract text content.
    throw UnimplementedError('DocumentPreprocessor.preprocess: TODO');
  }

  String _getContentType(String path) {
    final ext = '.${path.split('.').last.toLowerCase()}';
    return switch (ext) {
      '.pdf' => 'application/pdf',
      '.png' => 'image/png',
      '.jpg' => 'image/jpeg',
      '.jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }
}
