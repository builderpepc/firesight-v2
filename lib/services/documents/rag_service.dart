/// Document indexing and retrieval-augmented generation (RAG) via Cactus.
///
/// Stub — implementation deferred pending Cactus RAG API integration.
/// When implemented, use cactusIndexCreate / cactusIndexSearch from lib/cactus.dart.
class RagService {
  /// Stores a document for RAG indexing (auto-chunking).
  Future<void> storeDocument(String id, String content) async {
    // TODO: Call cactusIndexCreate + store with auto-chunking.
    throw UnimplementedError('RagService.storeDocument: TODO');
  }

  /// Queries RAG for relevant context to pass to LLM.
  Future<String> query(String question) async {
    // TODO: Call cactusIndexSearch for vector similarity.
    throw UnimplementedError('RagService.query: TODO');
  }

  Future<void> dispose() async {
    // TODO: Destroy Cactus index handle.
  }
}
