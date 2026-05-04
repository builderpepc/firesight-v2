import 'package:cactus/cactus.dart';

/// CactusRAG: storeDocument, query for building document Q&A.
class RagService {
  RagService(this._rag);

  final CactusRAG _rag;

  /// Stores a document for RAG indexing (auto-chunking).
  Future<void> storeDocument(String id, String content) async {
    // TODO: Call CactusRAG.storeDocument with auto-chunking.
    throw UnimplementedError('RagService.storeDocument: TODO');
  }

  /// Queries RAG for relevant context to pass to LLM.
  Future<String> query(String question) async {
    // TODO: Call CactusRAG.search for vector similarity.
    throw UnimplementedError('RagService.query: TODO');
  }

  Future<void> dispose() async {
    // TODO: Release CactusRAG resources.
  }
}
