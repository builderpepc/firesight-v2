#include "../cactus\_engine.h"
#include "utils.h"
#include "telemetry.h"
#include
#include
#include
#include
#include
#include
#include
#include
#include

using namespace cactus::engine;
using namespace cactus::ffi;

static constexpr size\_t RAG\_MAX\_CHUNK\_TOKENS = 128;
static constexpr size\_t RAG\_MIN\_CHUNK\_TOKENS = 24;
static constexpr size\_t RAG\_CHUNK\_OVERLAP = 32;

static void apply\_no\_cloud\_telemetry\_env() {
 if (cactus::ffi::env\_flag\_enabled("CACTUS\_NO\_CLOUD\_TELE")) {
 cactus::telemetry::setCloudDisabled(true);
 }
}

static time\_t get\_file\_mtime(const std::string& path) {
 struct stat st;
 if (stat(path.c\_str(), &st) == 0) {
 return st.st\_mtime;
 }
 return 0;
}

static bool corpus\_is\_stale(const std::string& corpus\_dir) {
 std::string index\_path = corpus\_dir + "/index.bin";
 time\_t index\_mtime = get\_file\_mtime(index\_path);
 if (index\_mtime == 0) return true;

 DIR\* dir = opendir(corpus\_dir.c\_str());
 if (!dir) return true;

 struct dirent\* entry;
 while ((entry = readdir(dir)) != nullptr) {
 std::string name = entry->d\_name;
 if (name == "." \|\| name == "..") continue;
 if (name == "index.bin" \|\| name == "data.bin") continue;

 bool is\_corpus\_file = false;
 if (name.size() > 4 && name.substr(name.size() - 4) == ".txt") is\_corpus\_file = true;
 if (name.size() > 3 && name.substr(name.size() - 3) == ".md") is\_corpus\_file = true;

 if (is\_corpus\_file) {
 std::string full\_path = corpus\_dir + "/" + name;
 time\_t file\_mtime = get\_file\_mtime(full\_path);
 if (file\_mtime > index\_mtime) {
 closedir(dir);
 CACTUS\_LOG\_INFO("init", "Corpus file " << name << " is newer than index, rebuilding");
 return true;
 }
 }
 }
 closedir(dir);
 return false;
}

static std::string read\_file\_contents(const std::string& path) {
 std::ifstream file(path);
 if (!file.is\_open()) return "";
 std::stringstream buffer;
 buffer << file.rdbuf();
 return buffer.str();
}

static std::vector scan\_corpus\_files(const std::string& corpus\_dir) {
 std::vector files;
 DIR\* dir = opendir(corpus\_dir.c\_str());
 if (!dir) return files;

 struct dirent\* entry;
 while ((entry = readdir(dir)) != nullptr) {
 std::string name = entry->d\_name;
 if (name == "." \|\| name == "..") continue;
 if (name == "index.bin" \|\| name == "data.bin") continue;

 std::string full\_path = corpus\_dir + "/" + name;
 struct stat st;
 if (stat(full\_path.c\_str(), &st) == 0 && S\_ISREG(st.st\_mode)) {
 if (name.size() > 4 && (name.substr(name.size() - 4) == ".txt" \|\| name.substr(name.size() - 3) == ".md")) {
 files.push\_back(full\_path);
 }
 }
 }
 closedir(dir);
 return files;
}

static std::vector split\_into\_paragraphs(const std::string& content) {
 std::vector paragraphs;
 std::string current;

 size\_t i = 0;
 while (i < content.size()) {
 // Check for markdown header
 if (content\[i\] == '#' && (i == 0 \|\| content\[i-1\] == '\\n')) {
 if (!current.empty()) {
 paragraphs.push\_back(current);
 current.clear();
 }
 // Include the header line
 while (i < content.size() && content\[i\] != '\\n') {
 current += content\[i++\];
 }
 if (i < content.size()) current += content\[i++\];
 continue;
 }

 // Check for double newline (paragraph break)
 if (content\[i\] == '\\n' && i + 1 < content.size() && content\[i+1\] == '\\n') {
 current += content\[i\];
 if (!current.empty() && current != "\\n") {
 paragraphs.push\_back(current);
 current.clear();
 }
 i++;
 // Skip multiple blank lines
 while (i < content.size() && content\[i\] == '\\n') i++;
 continue;
 }

 current += content\[i++\];
 }

 if (!current.empty()) {
 paragraphs.push\_back(current);
 }

 return paragraphs;
}

static std::vector\> chunk\_corpus(
 const std::vector& file\_paths,
 Tokenizer\* tokenizer
) {
 std::vector\> chunks;

 for (const auto& path : file\_paths) {
 std::string content = read\_file\_contents(path);
 if (content.empty()) continue;

 std::string filename = path;
 size\_t last\_slash = path.find\_last\_of("/\\\");
 if (last\_slash != std::string::npos) {
 filename = path.substr(last\_slash + 1);
 }

 auto paragraphs = split\_into\_paragraphs(content);

 std::string current\_chunk;
 size\_t current\_tokens = 0;

 for (const auto& para : paragraphs) {
 std::vector para\_tokens = tokenizer->encode(para);
 size\_t para\_token\_count = para\_tokens.size();

 // If paragraph alone is too large, split it by tokens
 if (para\_token\_count > RAG\_MAX\_CHUNK\_TOKENS) {
 // Flush current chunk first
 if (!current\_chunk.empty()) {
 chunks.emplace\_back(current\_chunk, filename);
 current\_chunk.clear();
 current\_tokens = 0;
 }

 // Split large paragraph by sentences or fixed tokens
 size\_t stride = RAG\_MAX\_CHUNK\_TOKENS - RAG\_CHUNK\_OVERLAP;
 for (size\_t i = 0; i < para\_tokens.size(); i += stride) {
 size\_t end = std::min(i + RAG\_MAX\_CHUNK\_TOKENS, para\_tokens.size());
 std::vector chunk\_tokens(para\_tokens.begin() + i, para\_tokens.begin() + end);
 std::string chunk\_text = tokenizer->decode(chunk\_tokens);
 chunks.emplace\_back(chunk\_text, filename);
 if (end >= para\_tokens.size()) break;
 }
 continue;
 }

 // Would adding this paragraph exceed max?
 if (current\_tokens + para\_token\_count > RAG\_MAX\_CHUNK\_TOKENS && !current\_chunk.empty()) {
 chunks.emplace\_back(current\_chunk, filename);
 current\_chunk.clear();
 current\_tokens = 0;
 }

 // Add paragraph to current chunk
 if (!current\_chunk.empty()) current\_chunk += "\\n";
 current\_chunk += para;
 current\_tokens += para\_token\_count;
 }

 // Don't forget the last chunk
 if (!current\_chunk.empty() && current\_tokens >= RAG\_MIN\_CHUNK\_TOKENS) {
 chunks.emplace\_back(current\_chunk, filename);
 } else if (!current\_chunk.empty() && !chunks.empty()) {
 // Append small remaining chunk to previous
 chunks.back().first += "\\n" + current\_chunk;
 } else if (!current\_chunk.empty()) {
 chunks.emplace\_back(current\_chunk, filename);
 }
 }

 return chunks;
}

static bool build\_corpus\_index(CactusModelHandle\* handle, const std::string& corpus\_dir) {
 CACTUS\_LOG\_INFO("init", "Building corpus index from: " << corpus\_dir);

 auto\* tokenizer = handle->model->get\_tokenizer();
 if (!tokenizer) {
 CACTUS\_LOG\_ERROR("init", "No tokenizer available for corpus indexing");
 return false;
 }

 auto file\_paths = scan\_corpus\_files(corpus\_dir);
 if (file\_paths.empty()) {
 CACTUS\_LOG\_WARN("init", "No .txt or .md files found in corpus directory");
 return false;
 }

 CACTUS\_LOG\_INFO("init", "Found " << file\_paths.size() << " corpus files");

 auto chunks = chunk\_corpus(file\_paths, tokenizer);
 if (chunks.empty()) {
 CACTUS\_LOG\_WARN("init", "No chunks generated from corpus");
 return false;
 }

 CACTUS\_LOG\_INFO("init", "Generated " << chunks.size() << " chunks from corpus");

 std::vector test\_tokens = tokenizer->encode("test");
 std::vector test\_embedding = handle->model->get\_embeddings(test\_tokens, true, true);
 if (test\_embedding.empty()) {
 CACTUS\_LOG\_ERROR("init", "Failed to get embedding dimension");
 return false;
 }
 size\_t embedding\_dim = test\_embedding.size();
 handle->corpus\_embedding\_dim = embedding\_dim;

 CACTUS\_LOG\_INFO("init", "Embedding dimension: " << embedding\_dim);

 std::string index\_path = corpus\_dir + "/index.bin";
 std::string data\_path = corpus\_dir + "/data.bin";

 std::remove(index\_path.c\_str());
 std::remove(data\_path.c\_str());

 try {
 handle->corpus\_index = std::make\_unique(index\_path, data\_path, embedding\_dim);
 } catch (const std::exception& e) {
 CACTUS\_LOG\_ERROR("init", "Failed to create index: " << e.what());
 return false;
 }

 std::vector docs;
 docs.reserve(chunks.size());

 for (size\_t i = 0; i < chunks.size(); ++i) {
 const auto& \[chunk\_text, source\_file\] = chunks\[i\];

 std::vector tokens = tokenizer->encode(chunk\_text);
 std::vector embedding = handle->model->get\_embeddings(tokens, true, true);

 if (embedding.size() != embedding\_dim) {
 CACTUS\_LOG\_WARN("init", "Skipping chunk " << i << " - embedding dimension mismatch");
 continue;
 }

 docs.push\_back(index::Document{
 static\_cast(i),
 std::move(embedding),
 chunk\_text,
 source\_file
 });

 if ((i + 1) % 50 == 0) {
 CACTUS\_LOG\_INFO("init", "Embedded " << (i + 1) << "/" << chunks.size() << " chunks");
 }
 }

 if (docs.empty()) {
 CACTUS\_LOG\_ERROR("init", "No documents to add to index");
 return false;
 }

 try {
 handle->corpus\_index->add\_documents(docs);
 } catch (const std::exception& e) {
 CACTUS\_LOG\_ERROR("init", "Failed to add documents to index: " << e.what());
 return false;
 }

 CACTUS\_LOG\_INFO("init", "Corpus index built successfully with " << docs.size() << " chunks");
 return true;
}

static bool load\_corpus\_index(CactusModelHandle\* handle, const std::string& corpus\_dir) {
 std::string index\_path = corpus\_dir + "/index.bin";
 std::string data\_path = corpus\_dir + "/data.bin";

 struct stat st;
 if (stat(index\_path.c\_str(), &st) != 0 \|\| stat(data\_path.c\_str(), &st) != 0) {
 return false;
 }

 if (corpus\_is\_stale(corpus\_dir)) {
 return false;
 }

 auto\* tokenizer = handle->model->get\_tokenizer();
 std::vector test\_tokens = tokenizer->encode("test");
 std::vector test\_embedding = handle->model->get\_embeddings(test\_tokens, true, true);
 if (test\_embedding.empty()) {
 CACTUS\_LOG\_ERROR("init", "Failed to get embedding dimension for index loading");
 return false;
 }
 size\_t embedding\_dim = test\_embedding.size();
 handle->corpus\_embedding\_dim = embedding\_dim;

 try {
 handle->corpus\_index = std::make\_unique(index\_path, data\_path, embedding\_dim);
 CACTUS\_LOG\_INFO("init", "Loaded existing corpus index from: " << corpus\_dir);
 return true;
 } catch (const std::exception& e) {
 CACTUS\_LOG\_WARN("init", "Failed to load existing index: " << e.what());
 return false;
 }
}

std::string last\_error\_message;

bool matches\_stop\_sequence(const std::vector& generated\_tokens,
 const std::vector>& stop\_sequences) {
 for (const auto& stop\_seq : stop\_sequences) {
 if (stop\_seq.empty()) continue;
 if (generated\_tokens.size() >= stop\_seq.size()) {
 if (std::equal(stop\_seq.rbegin(), stop\_seq.rend(), generated\_tokens.rbegin()))
 return true;
 }
 }
 return false;
}

extern "C" {

const char\* cactus\_get\_last\_error() {
 return last\_error\_message.c\_str();
}

cactus\_model\_t cactus\_init(const char\* model\_path, const char\* corpus\_dir, bool cache\_index) {
 constexpr size\_t DEFAULT\_CONTEXT\_SIZE = 512; // matches default sliding window size

 std::string model\_path\_str = model\_path ? std::string(model\_path) : "unknown";

 std::string model\_name = model\_path\_str;
 size\_t last\_slash = model\_path\_str.find\_last\_of("/\\\");
 if (last\_slash != std::string::npos) {
 model\_name = model\_path\_str.substr(last\_slash + 1);
 }

 CACTUS\_LOG\_INFO("init", "Loading model: " << model\_name << " from " << model\_path\_str);

 apply\_no\_cloud\_telemetry\_env();
 cactus::telemetry::init(nullptr, model\_path\_str.c\_str(), nullptr);

 auto \_\_cactus\_init\_start = std::chrono::steady\_clock::now();

 try {
 auto\* handle = new CactusModelHandle();
 handle->model = create\_model(model\_path);
 handle->model\_name = model\_name;

 if (!handle->model) {
 last\_error\_message = "Failed to create model - check config.txt exists at: " + model\_path\_str;
 CACTUS\_LOG\_ERROR("init", last\_error\_message);
 {
 auto \_\_cactus\_init\_err\_dur = std::chrono::duration\_cast(std::chrono::steady\_clock::now() - \_\_cactus\_init\_start).count();
 cactus::telemetry::recordInit(model\_name.c\_str(), false, static\_cast(\_\_cactus\_init\_err\_dur), last\_error\_message.c\_str());
 }
 delete handle;
 return nullptr;
 }

 if (!handle->model->init(model\_path, DEFAULT\_CONTEXT\_SIZE)) {
 last\_error\_message = "Failed to initialize model - check weight files at: " + model\_path\_str;
 CACTUS\_LOG\_ERROR("init", last\_error\_message);
 {
 auto \_\_cactus\_init\_err\_dur = std::chrono::duration\_cast(std::chrono::steady\_clock::now() - \_\_cactus\_init\_start).count();
 cactus::telemetry::recordInit(model\_name.c\_str(), false, static\_cast(\_\_cactus\_init\_err\_dur), last\_error\_message.c\_str());
 }
 delete handle;
 return nullptr;
 }

 if (corpus\_dir != nullptr && strlen(corpus\_dir) > 0) {
 handle->corpus\_dir = std::string(corpus\_dir);

 bool loaded = false;
 if (cache\_index) {
 loaded = load\_corpus\_index(handle, handle->corpus\_dir);
 }

 if (!loaded) {
 CACTUS\_LOG\_INFO("init", (cache\_index ? "No existing index found, building new corpus index" : "Building fresh corpus index (caching disabled)"));
 if (!build\_corpus\_index(handle, handle->corpus\_dir)) {
 CACTUS\_LOG\_WARN("init", "Failed to build corpus index - RAG disabled");
 }
 }
 }

 CACTUS\_LOG\_INFO("init", "Model loaded successfully: " << model\_name);
 {
 auto \_\_cactus\_init\_ok\_dur = std::chrono::duration\_cast(std::chrono::steady\_clock::now() - \_\_cactus\_init\_start).count();
 cactus::telemetry::recordInit(model\_name.c\_str(), true, static\_cast(\_\_cactus\_init\_ok\_dur), "");
 }

 return handle;
 } catch (const std::exception& e) {
 last\_error\_message = "Exception during init: " + std::string(e.what());
 CACTUS\_LOG\_ERROR("init", last\_error\_message);
 {
 auto \_\_cactus\_init\_err\_dur = std::chrono::duration\_cast(std::chrono::steady\_clock::now() - \_\_cactus\_init\_start).count();
 cactus::telemetry::recordInit(model\_name.c\_str(), false, static\_cast(\_\_cactus\_init\_err\_dur), last\_error\_message.c\_str());
 }
 return nullptr;
 } catch (...) {
 last\_error\_message = "Unknown exception during model initialization";
 CACTUS\_LOG\_ERROR("init", last\_error\_message);
 {
 auto \_\_cactus\_init\_err\_dur = std::chrono::duration\_cast(std::chrono::steady\_clock::now() - \_\_cactus\_init\_start).count();
 cactus::telemetry::recordInit(model\_name.c\_str(), false, static\_cast(\_\_cactus\_init\_err\_dur), last\_error\_message.c\_str());
 }
 return nullptr;
 }
}

void cactus\_destroy(cactus\_model\_t model) {
 if (model) delete static\_cast(model);
}

void cactus\_reset(cactus\_model\_t model) {
 if (!model) return;
 auto\* handle = static\_cast(model);
 handle->model->reset\_cache();
 handle->processed\_tokens.clear();
 handle->processed\_images.clear();
 handle->user\_audio\_counts.clear();
}

void cactus\_stop(cactus\_model\_t model) {
 if (!model) return;
 auto\* handle = static\_cast(model);
 handle->should\_stop = true;
}

}