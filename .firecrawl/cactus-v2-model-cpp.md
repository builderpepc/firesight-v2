#include "engine.h"
#include "../models/model.h"
#include "cactus\_graph.h"
#include
#include
#include
#include
#include
#include
#include
#include
#include
#include
#include

namespace cactus {
namespace engine {

void ConvCache::init(size\_t layers, size\_t hidden\_dim, size\_t window\_len, Precision model\_precision) {
 num\_layers = layers;
 hidden\_size = hidden\_dim;
 window\_size = window\_len;
 precision = model\_precision;
 element\_size = PrecisionTraits::size\_of(precision);

 size\_t state\_bytes = window\_size \* hidden\_size \* element\_size;
 layer\_states.resize(num\_layers);
 for (auto& state : layer\_states) {
 state.data.resize(state\_bytes);
 std::memset(state.data.data(), 0, state\_bytes);
 state.head = 0;
 state.count = 0;
 }
}

ConvCache::CircularView ConvCache::get\_window(size\_t layer) const {
 CircularView view{};
 if (layer >= num\_layers) {
 return view;
 }

 const auto& state = layer\_states\[layer\];
 if (state.count == 0) {
 return view;
 }

 size\_t stride = hidden\_size \* element\_size;
 if (state.count < window\_size) {
 view.ptr1 = state.data.data();
 view.len1 = state.count;
 view.total\_len = state.count;
 return view;
 }

 view.ptr1 = state.data.data();
 view.len1 = state.head;
 view.ptr2 = state.data.data() + state.head \* stride;
 view.len2 = window\_size - state.head;
 view.total\_len = window\_size;
 return view;
}

void ConvCache::update(CactusGraph\* gb, size\_t layer, const size\_t bx\_node) {
 if (layer >= num\_layers \|\| !bx\_node \|\| window\_size == 0 \|\| hidden\_size == 0) {
 return;
 }

 auto& state = layer\_states\[layer\];
 const void\* output\_ptr = gb->get\_output(bx\_node);
 if (!output\_ptr) {
 return;
 }

 const auto& buffer = gb->get\_output\_buffer(bx\_node);
 const size\_t stride\_bytes = hidden\_size \* element\_size;

 size\_t rows = 1;
 if (!buffer.shape.empty()) {
 rows = buffer.shape.size() == 1 ? 1 : buffer.shape\[0\];
 }

 if (buffer.total\_size > 0 && hidden\_size > 0) {
 size\_t inferred = buffer.total\_size / hidden\_size;
 if (inferred > 0) {
 rows = inferred;
 }
 }

 if (rows == 0) {
 return;
 }

 size\_t copy\_rows = std::min(rows, window\_size);
 size\_t start\_row = rows > window\_size ? rows - window\_size : 0;
 const auto\* src = static\_cast(output\_ptr) + start\_row \* stride\_bytes;

 for (size\_t i = 0; i < copy\_rows; ++i) {
 std::memcpy(state.data.data() + state.head \* stride\_bytes, src + i \* stride\_bytes, stride\_bytes);
 state.head = (state.head + 1) % window\_size;
 if (state.count < window\_size) {
 ++state.count;
 }
 }
}

void ConvCache::reset() {
 for (auto& state : layer\_states) {
 std::fill(state.data.begin(), state.data.end(), 0);
 state.head = 0;
 state.count = 0;
 }
}

Model::Model()
 : graph\_handle\_(nullptr),
 config\_(),
 tokenizer\_(nullptr),
 initialized\_(false),
 attention\_scale\_(0.0f),
 output\_weight\_node\_id\_(0),
 owns\_graph\_(false) {
}

Model::Model(const Config& config)
 : graph\_handle\_(nullptr),
 config\_(config),
 tokenizer\_(nullptr),
 initialized\_(false),
 attention\_scale\_(0.0f),
 output\_weight\_node\_id\_(0),
 owns\_graph\_(false) {
}

Model::~Model() {
 if (graph\_handle\_ && owns\_graph\_) {
 delete static\_cast(graph\_handle\_);
 }
}

bool Model::init(const std::string& model\_folder, size\_t context\_size, const std::string& system\_prompt, bool do\_warmup) {
 if (initialized\_) {
 return true;
 }
 auto\* gb = new CactusGraph();
 graph\_handle\_ = gb;
 owns\_graph\_ = true;
 embedding\_file\_path\_ = model\_folder + "/token\_embeddings.weights";
 return init\_internal(gb, model\_folder, context\_size, system\_prompt, do\_warmup);
}

bool Model::init(CactusGraph\* external\_graph, const std::string& model\_folder, size\_t context\_size,
 const std::string& system\_prompt, bool do\_warmup) {
 if (!external\_graph) {
 throw std::invalid\_argument("External graph pointer must not be null");
 }
 if (initialized\_) {
 graph\_handle\_ = external\_graph;
 owns\_graph\_ = false;
 return true;
 }

 owns\_graph\_ = false;
 graph\_handle\_ = external\_graph;
 return init\_internal(external\_graph, model\_folder, context\_size, system\_prompt, do\_warmup);
}

bool Model::init\_internal(CactusGraph\* gb, const std::string& model\_folder, size\_t context\_size,
 const std::string& system\_prompt, bool do\_warmup) {
 (void)system\_prompt;
 CACTUS\_LOG\_DEBUG("model", "Initializing model from: " << model\_folder);
 model\_folder\_path\_ = model\_folder;
 std::string config\_path = model\_folder + "/config.txt";

 if (!config\_.from\_json(config\_path)) {
 CACTUS\_LOG\_ERROR("model", "Model initialization failed - config not loaded from: " << model\_folder);
 return false;
 }

 std::string vocab\_file = model\_folder + "/vocab.txt";
 std::string merges\_file = model\_folder + "/merges.txt";
 std::string tokenizer\_config\_file = model\_folder + "/tokenizer\_config.txt";
 TokenizerRuntimeConfig tokenizer\_runtime\_config = load\_tokenizer\_runtime\_config(tokenizer\_config\_file);

 std::ifstream merges\_check(merges\_file);
 bool has\_merges = false;
 if (merges\_check.is\_open()) {
 std::string line;
 int line\_count = 0;
 while (std::getline(merges\_check, line) && line\_count < 10) {
 if (!line.empty() && line\[0\] != '#') {
 has\_merges = true;
 break;
 }
 line\_count++;
 }
 merges\_check.close();
 }

 if (tokenizer\_runtime\_config.tokenizer\_type == TokenizerRuntimeConfig::TokenizerType::BPE \|\|
 (tokenizer\_runtime\_config.tokenizer\_type == TokenizerRuntimeConfig::TokenizerType::UNKNOWN && has\_merges)) {
 tokenizer\_ = std::make\_unique();
 } else {
 tokenizer\_ = std::make\_unique();
 }

 if (!tokenizer\_->load\_vocabulary\_with\_config(vocab\_file, merges\_file, tokenizer\_config\_file)) {
 return false;
 }

 graph\_handle\_ = gb;

 embedding\_file\_path\_ = model\_folder + "/token\_embeddings.weights";

 load\_weights\_to\_graph(gb);

 if (config\_.model\_type == Config::ModelType::GEMMA3N \|\| config\_.model\_type == Config::ModelType::GEMMA4) {
 attention\_scale\_ = 1.0f;
 } else if (config\_.model\_type == Config::ModelType::GEMMA) {
 attention\_scale\_ = 1.0f / std::sqrt(256.0f);
 } else {
 attention\_scale\_ = 1.0f / std::sqrt(static\_cast(config\_.attention\_head\_dim));
 }

 cache\_max\_seq\_len\_ = context\_size;
 cache\_window\_size\_ = std::min(context\_size, size\_t(512));
 cache\_sink\_size\_ = 4;
 const char\* env\_window = std::getenv("CACTUS\_KV\_WINDOW\_SIZE");
 const char\* env\_sink = std::getenv("CACTUS\_KV\_SINK\_SIZE");
 if (env\_window) {
 cache\_window\_size\_ = std::stoul(env\_window);
 }
 if (env\_sink) {
 cache\_sink\_size\_ = std::stoul(env\_sink);
 }

 post\_init();

 initialized\_ = true;

 if (do\_warmup) {
 std::vector warmup\_tokens = {2};
 forward(warmup\_tokens);
 auto\* gb = static\_cast(graph\_handle\_);
 gb->execute();
 }

 reset\_cache();
 return true;
}

size\_t Model::forward(const std::vector& /\*mel\_bins\*/, const std::vector& tokens, bool use\_cache){
 return forward(tokens, use\_cache);
}

void Model::prefill(const std::vector& tokens, size\_t chunk\_size, const std::string& profile\_file) {
 if (tokens.empty()) {
 return;
 }

 if (has\_npu\_prefill()) {
 size\_t npu\_chunk\_size = static\_cast(npu\_prefill\_->get\_chunk\_size());
 if (tokens.size() > npu\_chunk\_size) {
 prefill\_npu(tokens);
 return;
 }
 }

 auto\* gb = static\_cast(graph\_handle\_);

 auto process\_chunk = \[&\](const std::vector& chunk) {
 forward(chunk, true);
 gb->execute(profile\_file);
 post\_execute\_updates(gb, chunk.size());
 cache\_total\_seq\_len\_ += chunk.size();
 };

 if (tokens.size() <= chunk\_size) {
 process\_chunk(tokens);
 return;
 }

 size\_t num\_full\_chunks = (tokens.size() - 1) / chunk\_size;

 for (size\_t chunk\_idx = 0; chunk\_idx < num\_full\_chunks; ++chunk\_idx) {
 size\_t start = chunk\_idx \* chunk\_size;
 size\_t end = start + chunk\_size;
 std::vector chunk(tokens.begin() + start, tokens.begin() + end);
 if (chunk\_idx == 1) {
 gb->set\_prefill\_mode(true);
 }
 process\_chunk(chunk);
 }

 gb->set\_prefill\_mode(false);
 size\_t final\_start = num\_full\_chunks \* chunk\_size;
 std::vector final\_chunk(tokens.begin() + final\_start, tokens.end());
 process\_chunk(final\_chunk);
}

void Model::prefill\_with\_images(const std::vector& tokens, const std::vector& image\_paths,
 const std::string& profile\_file) {
 (void)image\_paths;
 prefill(tokens, get\_prefill\_chunk\_size(), profile\_file);
}

uint32\_t Model::decode(const std::vector& tokens, float temperature, float top\_p,
 size\_t top\_k, const std::string& profile\_file, float\* out\_entropy,
 float min\_p, float repetition\_penalty) {

 if (temperature < 0) {
 temperature = config\_.default\_temperature;
 }
 if (top\_p < 0) {
 top\_p = config\_.default\_top\_p;
 }
 if (top\_k == 0) {
 top\_k = config\_.default\_top\_k;
 }
 auto final\_hidden = forward(tokens, true);

 auto\* gb = static\_cast(graph\_handle\_);
 auto backend = config\_.default\_backend == Config::Backend::CPU
 ? ComputeBackend::CPU
 : ComputeBackend::NPU;

 auto last\_hidden = gb->index(final\_hidden, tokens.size() - 1, 0);
 const auto& last\_hidden\_buf = gb->get\_output\_buffer(last\_hidden);
 size\_t hidden\_dim = last\_hidden\_buf.shape\[0\];
 last\_hidden = gb->reshape(last\_hidden, {1, hidden\_dim});

 auto logits\_node\_id = gb->matmul(last\_hidden, output\_weight\_node\_id\_, true, backend);

 if (config\_.final\_logit\_softcapping > 0.0f) {
 float inv\_cap = 1.0f / config\_.final\_logit\_softcapping;
 logits\_node\_id = gb->scalar\_multiply(logits\_node\_id, inv\_cap);
 logits\_node\_id = gb->tanh(logits\_node\_id);
 logits\_node\_id = gb->scalar\_multiply(logits\_node\_id, config\_.final\_logit\_softcapping);
 }
 auto sampled\_token\_id = sample\_token(gb, logits\_node\_id, temperature, top\_p, top\_k, min\_p, repetition\_penalty);

 gb->execute(profile\_file);

 compute\_entropy(gb, logits\_node\_id, out\_entropy);

 post\_execute\_updates(gb, tokens.size());
 cache\_total\_seq\_len\_ += tokens.size();

 auto\* output\_ptr = gb->get\_output(sampled\_token\_id);
 uint32\_t result\_token = \*static\_cast(output\_ptr);
 record\_sampled\_token(result\_token);
 return result\_token;
}

size\_t Model::sample\_token(CactusGraph\* gb, size\_t logits\_node\_id, float temperature, float top\_p, size\_t top\_k,
 float min\_p, float repetition\_penalty,
 const std::unordered\_map\\* extra\_bias) const {
 auto combined\_bias = tool\_constrainer\_.get\_bias();
 for (const auto& \[token\_id, boost\] : vocab\_bias\_) {
 combined\_bias\[token\_id\] += boost;
 }
 if (extra\_bias) {
 for (const auto& \[token\_id, boost\] : \*extra\_bias) {
 combined\_bias\[token\_id\] += boost;
 }
 }
 if (!token\_history\_.empty() && repetition\_penalty > 1.0f && std::isfinite(repetition\_penalty)) {
 float log\_penalty = std::log(repetition\_penalty);
 for (uint32\_t tok : token\_history\_) {
 combined\_bias\[tok\] -= log\_penalty;
 }
 }
 return gb->sample\_with\_options(logits\_node\_id, temperature, top\_p, min\_p, 1.0f, top\_k, combined\_bias);
}

void Model::compute\_entropy(CactusGraph\* gb, size\_t logits\_node\_id, float\* out\_entropy) {
 if (!out\_entropy) return;

 const auto& logits\_buf = gb->get\_output\_buffer(logits\_node\_id);
 void\* logits\_ptr = gb->get\_output(logits\_node\_id);
 size\_t vocab\_size = logits\_buf.shape.back();
 size\_t seq\_len = 1;
 if (logits\_buf.shape.size() >= 2)
 seq\_len = logits\_buf.shape\[logits\_buf.shape.size() - 2\];
 size\_t row\_offset = (seq\_len > 0 ? (seq\_len - 1) \* vocab\_size : 0);

 std::vector logits(vocab\_size);
 if (logits\_buf.precision == Precision::FP32) {
 float\* src = static\_cast(logits\_ptr) + row\_offset;
 std::copy(src, src + vocab\_size, logits.begin());
 } else if (logits\_buf.precision == Precision::FP16) {
 \_\_fp16\* src = static\_cast<\_\_fp16\*>(logits\_ptr) + row\_offset;
 Quantization::fp16\_to\_fp32(src, logits.data(), vocab\_size);
 } else {
 int8\_t\* src = static\_cast(logits\_ptr) + row\_offset;
 Quantization::int8\_to\_fp32(src, logits.data(), vocab\_size, 1.0f);
 }

 float max\_logit = \*std::max\_element(logits.begin(), logits.end());
 double sum\_exp = 0.0;
 for (size\_t i = 0; i < vocab\_size; ++i)
 sum\_exp += std::exp(static\_cast(logits\[i\] - max\_logit));
 double log\_sum\_exp = static\_cast(max\_logit) + std::log(sum\_exp);

 double entropy = 0.0;
 for (size\_t i = 0; i < vocab\_size; ++i) {
 double log\_prob = static\_cast(logits\[i\]) - log\_sum\_exp;
 double prob = std::exp(log\_prob);
 if (prob > 1e-10)
 entropy -= prob \* log\_prob;
 }

 double max\_entropy = std::log(static\_cast(vocab\_size));
 \*out\_entropy = static\_cast(entropy / max\_entropy);
}

uint32\_t Model::decode\_with\_audio(const std::vector& tokens, const std::vector& /\*mel\_bins\*/, float temperature, float top\_p, size\_t top\_k, const std::string& profile\_file, float\* out\_entropy,
 float min\_p, float repetition\_penalty,
 float\* /\*out\_token\_time\_start\*/, float\* /\*out\_token\_time\_end\*/){
 return decode(tokens, temperature, top\_p, top\_k, profile\_file, out\_entropy, min\_p, repetition\_penalty);
}

uint32\_t Model::decode\_with\_images(const std::vector& tokens, const std::vector& image\_paths,
 float temperature, float top\_p, size\_t top\_k, const std::string& profile\_file, float\* out\_entropy,
 float min\_p, float repetition\_penalty) {
 (void)image\_paths;
 return decode(tokens, temperature, top\_p, top\_k, profile\_file, out\_entropy, min\_p, repetition\_penalty);
}

std::vector Model::get\_image\_embeddings(const std::string& /\*image\_path\*/) {
 throw std::runtime\_error("Image embeddings not supported for this model type");
}

std::vector Model::get\_audio\_embeddings(const std::vector& /\*mel\_bins\*/) {
 throw std::runtime\_error("Audio embeddings not supported for this model type");
}

void Model::init\_graph\_cache(CactusGraph\* gb) {
 auto layer\_dims = get\_kv\_layer\_dims();
 auto layer\_heads = get\_kv\_layer\_heads();
 auto layer\_windows = get\_kv\_layer\_windows();
 size\_t n = config\_.num\_layers;

 graph\_cache\_k\_nodes\_.resize(n, 0);
 graph\_cache\_v\_nodes\_.resize(n, 0);

 for (size\_t i = 0; i < n; i++) {
 if (layer\_dims\[i\] == 0) continue; // shared layers have dim=0
 size\_t window = (i < layer\_windows.size()) ? layer\_windows\[i\] : cache\_window\_size\_;
 size\_t max\_seq = (window > 0) ? window : cache\_max\_seq\_len\_;
 graph\_cache\_k\_nodes\_\[i\] = gb->kv\_cache\_state(max\_seq, layer\_heads\[i\], layer\_dims\[i\], window, cache\_sink\_size\_);
 graph\_cache\_v\_nodes\_\[i\] = gb->kv\_cache\_state(max\_seq, layer\_heads\[i\], layer\_dims\[i\], window, cache\_sink\_size\_);
 }
 cache\_total\_seq\_len\_ = 0;
}

void Model::invalidate\_graph\_cache(CactusGraph\* gb) {
 for (size\_t i = 0; i < graph\_cache\_k\_nodes\_.size(); i++) {
 if (graph\_cache\_k\_nodes\_\[i\] != 0) gb->invalidate\_persistent(graph\_cache\_k\_nodes\_\[i\]);
 if (graph\_cache\_v\_nodes\_\[i\] != 0) gb->invalidate\_persistent(graph\_cache\_v\_nodes\_\[i\]);
 }
 graph\_cache\_k\_nodes\_.clear();
 graph\_cache\_v\_nodes\_.clear();
 cache\_total\_seq\_len\_ = 0;
}

void Model::reset\_cache() {
 if (graph\_handle\_) {
 auto\* gb = static\_cast(graph\_handle\_);
 invalidate\_graph\_cache(gb);
 init\_graph\_cache(gb);
 }
 token\_history\_.clear();
}

void Model::set\_cache\_window(size\_t window\_size, size\_t sink\_size) {
 cache\_window\_size\_ = window\_size;
 cache\_sink\_size\_ = sink\_size;
 if (graph\_handle\_) {
 auto\* gb = static\_cast(graph\_handle\_);
 invalidate\_graph\_cache(gb);
 init\_graph\_cache(gb);
 }
}

size\_t Model::get\_cache\_size() const {
 return cache\_total\_seq\_len\_;
}

void Model::remove\_thinking\_tokens(const std::vector>& ranges) {
 if (!ranges.empty()) {
 size\_t total\_removed = 0;
 for (const auto& r : ranges) total\_removed += r.second;
 if (cache\_total\_seq\_len\_ >= total\_removed)
 cache\_total\_seq\_len\_ -= total\_removed;
 else
 cache\_total\_seq\_len\_ = 0;
 }
}

std::vector Model::get\_embeddings(const std::vector& tokens, bool pooled, bool normalize, const std::string& profile\_file) {
 std::vector embeddings;
 auto final\_hidden = forward(tokens);

 auto\* gb = static\_cast(graph\_handle\_);
 auto\* output\_ptr = gb->get\_output(final\_hidden);
 const auto& output\_buffer = gb->get\_output\_buffer(final\_hidden);

 if (pooled) {
 auto pooled\_hidden = gb->mean(final\_hidden, 0);

 if (!profile\_file.empty()) {
 gb->execute(profile\_file);
 } else {
 gb->execute();
 }
 post\_execute\_updates(gb, tokens.size());
 auto\* pooled\_ptr = gb->get\_output(pooled\_hidden);
 const auto& pooled\_buffer = gb->get\_output\_buffer(pooled\_hidden);

 size\_t hidden\_dim = pooled\_buffer.total\_size;
 embeddings.resize(hidden\_dim);

 if (pooled\_buffer.precision == Precision::FP32) {
 float\* pooled\_data = static\_cast(pooled\_ptr);
 std::copy(pooled\_data, pooled\_data + hidden\_dim, embeddings.begin());
 } else if (pooled\_buffer.precision == Precision::FP16) {
 \_\_fp16\* pooled\_data = static\_cast<\_\_fp16\*>(pooled\_ptr);
 Quantization::fp16\_to\_fp32(pooled\_data, embeddings.data(), hidden\_dim);
 } else if (pooled\_buffer.precision == Precision::INT8) {
 int8\_t\* pooled\_data = static\_cast(pooled\_ptr);
 Quantization::int8\_to\_fp32(pooled\_data, embeddings.data(), hidden\_dim, 1.0f);
 }
 } else {
 if (!profile\_file.empty()) {
 gb->execute(profile\_file);
 } else {
 gb->execute();
 }
 post\_execute\_updates(gb, tokens.size());

 size\_t total\_size = output\_buffer.total\_size;
 embeddings.resize(total\_size);

 if (output\_buffer.precision == Precision::FP32) {
 float\* hidden\_states = static\_cast(output\_ptr);
 std::copy(hidden\_states, hidden\_states + total\_size, embeddings.begin());
 } else if (output\_buffer.precision == Precision::FP16) {
 \_\_fp16\* hidden\_states = static\_cast<\_\_fp16\*>(output\_ptr);
 for (size\_t i = 0; i < total\_size; i++) {
 embeddings\[i\] = static\_cast(hidden\_states\[i\]);
 }
 } else if (output\_buffer.precision == Precision::INT8) {
 int8\_t\* hidden\_states = static\_cast(output\_ptr);
 for (size\_t i = 0; i < total\_size; i++) {
 embeddings\[i\] = static\_cast(hidden\_states\[i\]);
 }
 }
 }

 if (normalize && !embeddings.empty()) {
 float norm\_sq = 0.0f;
 for (float v : embeddings) {
 norm\_sq += v \* v;
 }
 float norm = std::sqrt(norm\_sq);
 if (norm > 1e-12f) {
 float inv\_norm = 1.0f / norm;
 for (float& v : embeddings) {
 v \*= inv\_norm;
 }
 }
 }

 reset\_cache();

 return embeddings;
}

bool Config::from\_json(const std::string& config\_path) {
 std::ifstream file(config\_path);
 if (!file) {
 CACTUS\_LOG\_ERROR("config", "Failed to open config file: " << config\_path);
 return false;
 }

 std::string line;
 while (std::getline(file, line)) {
 if (line.empty() \|\| line\[0\] == '#') continue;

 size\_t eq\_pos = line.find('=');
 if (eq\_pos == std::string::npos) continue;

 std::string key = line.substr(0, eq\_pos);
 std::string value = line.substr(eq\_pos + 1);

 key.erase(0, key.find\_first\_not\_of(" \\t"));
 key.erase(key.find\_last\_not\_of(" \\t") + 1);
 value.erase(0, value.find\_first\_not\_of(" \\t"));
 value.erase(value.find\_last\_not\_of(" \\t") + 1);

 if (key == "vocab\_size") vocab\_size = static\_cast(std::stoul(value));
 else if (key == "bos\_token\_id") bos\_token\_id = static\_cast(std::stoul(value));
 else if (key == "eos\_token\_id") eos\_token\_id = static\_cast(std::stoul(value));
 else if (key == "num\_layers") num\_layers = static\_cast(std::stoul(value));
 else if (key == "hidden\_dim") hidden\_dim = static\_cast(std::stoul(value));
 else if (key == "ffn\_intermediate\_dim") ffn\_intermediate\_dim = static\_cast(std::stoul(value));
 else if (key == "attention\_heads") attention\_heads = static\_cast(std::stoul(value));
 else if (key == "attention\_kv\_heads") attention\_kv\_heads = static\_cast(std::stoul(value));
 else if (key == "attention\_head\_dim") attention\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "layer\_norm\_eps") layer\_norm\_eps = std::stof(value);
 else if (key == "rope\_theta") rope\_theta = std::stof(value);
 else if (key == "num\_experts") num\_experts = static\_cast(std::stoul(value));
 else if (key == "num\_shared\_experts") num\_shared\_experts = static\_cast(std::stoul(value));
 else if (key == "num\_top\_experts") num\_top\_experts = static\_cast(std::stoul(value));
 else if (key == "moe\_every\_n\_layers") moe\_every\_n\_layers = static\_cast(std::stoul(value));
 else if (key == "moe\_intermediate\_dim" \|\| key == "moe\_intermediate\_size") moe\_intermediate\_dim = static\_cast(std::stoul(value));
 else if (key == "num\_dense\_layers") num\_dense\_layers = static\_cast(std::stoul(value));
 else if (key == "num\_experts\_per\_tok") num\_experts\_per\_tok = static\_cast(std::stoul(value));
 else if (key == "norm\_topk\_prob") norm\_topk\_prob = (value == "true" \|\| value == "1");
 else if (key == "use\_expert\_bias") use\_expert\_bias = (value == "true" \|\| value == "1");
 else if (key == "routed\_scaling\_factor") routed\_scaling\_factor = std::stof(value);
 else if (key == "tie\_word\_embeddings") tie\_word\_embeddings = (value == "true" \|\| value == "1");
 else if (key == "vision\_hidden\_dim" \|\| key == "vision\_hidden\_size") vision\_hidden\_dim = static\_cast(std::stoul(value));
 else if (key == "vision\_num\_layers") vision\_num\_layers = static\_cast(std::stoul(value));
 else if (key == "vision\_attention\_heads") vision\_attention\_heads = static\_cast(std::stoul(value));
 else if (key == "vision\_image\_size") vision\_image\_size = static\_cast(std::stoul(value));
 else if (key == "vision\_patch\_size") vision\_patch\_size = static\_cast(std::stoul(value));
 else if (key == "vision\_num\_channels") vision\_num\_channels = static\_cast(std::stoul(value));
 else if (key == "vision\_embed\_dim") vision\_embed\_dim = static\_cast(std::stoul(value));
 else if (key == "visual\_tokens\_per\_img") visual\_tokens\_per\_img = static\_cast(std::stoul(value));
 else if (key == "use\_pixel\_shuffle") use\_pixel\_shuffle = (value == "true" \|\| value == "1");
 else if (key == "pixel\_shuffle\_factor") pixel\_shuffle\_factor = static\_cast(std::stoul(value));
 else if (key == "use\_image\_tokens") use\_image\_tokens = (value == "true" \|\| value == "1");
 else if (key == "image\_token\_id") image\_token\_id = static\_cast(std::stoul(value));
 else if (key == "use\_layout\_tags") use\_layout\_tags = (value == "true" \|\| value == "1");
 else if (key == "image\_seq\_len") image\_seq\_len = static\_cast(std::stoul(value));
 else if (key == "global\_image\_size") global\_image\_size = static\_cast(std::stoul(value));
 else if (key == "max\_tile\_size") max\_tile\_size = static\_cast(std::stoul(value));
 else if (key == "rescale\_factor") rescale\_factor = std::stof(value);
 else if (key == "image\_mean") image\_mean = std::stof(value);
 else if (key == "image\_std") image\_std = std::stof(value);
 else if (key == "downsample\_factor") downsample\_factor = static\_cast(std::stoul(value));
 else if (key == "min\_tiles") min\_tiles = static\_cast(std::stoul(value));
 else if (key == "max\_tiles") max\_tiles = static\_cast(std::stoul(value));
 else if (key == "use\_thumbnail") use\_thumbnail = (value == "true" \|\| value == "1");
 else if (key == "min\_image\_tokens") min\_image\_tokens = static\_cast(std::stoul(value));
 else if (key == "max\_image\_tokens") max\_image\_tokens = static\_cast(std::stoul(value));
 else if (key == "tile\_size") tile\_size = static\_cast(std::stoul(value));
 else if (key == "max\_pixels\_tolerance") max\_pixels\_tolerance = std::stof(value);
 else if (key == "do\_image\_splitting") do\_image\_splitting = (value == "true" \|\| value == "1");
 else if (key == "precision") {
 if (value == "INT8") precision = Precision::INT8;
 else if (value == "FP16") precision = Precision::FP16;
 else precision = Precision::FP32;
 }
 else if (key == "model\_type") {
 std::string mt = value;
 std::transform(mt.begin(), mt.end(), mt.begin(), ::tolower);
 if (mt == "qwen") model\_type = ModelType::QWEN;
 else if (mt == "qwen3p5" \|\| mt == "qwen3\_5") model\_type = ModelType::QWEN3P5;
 else if (mt == "gemma") model\_type = ModelType::GEMMA;
 else if (mt == "gemma3n") model\_type = ModelType::GEMMA3N;
 else if (mt == "lfm2") model\_type = ModelType::LFM2;
 else if (mt == "youtu") model\_type = ModelType::YOUTU;
 else if (mt == "needle") model\_type = ModelType::NEEDLE;
 else model\_type = ModelType::GEMMA4;
 }
 else if (key == "model\_variant") {
 std::string v = value;
 std::transform(v.begin(), v.end(), v.begin(), ::tolower);
 if (v == "vlm") model\_variant = ModelVariant::VLM;
 else if (v == "extract") model\_variant = ModelVariant::EXTRACT;
 else if (v == "rag") model\_variant = ModelVariant::RAG;
 else model\_variant = ModelVariant::DEFAULT;
 }
 else if (key == "conv\_L\_cache") conv\_L\_cache = static\_cast(std::stoul(value));
 else if (key == "layer\_types") {
 layer\_types.clear();
 std::string sanitized;
 sanitized.reserve(value.size());
 for (char c : value) {
 if (c == '\[' \|\| c == '\]' \|\| c == '\\'' \|\| c == '"') {
 continue;
 }
 sanitized.push\_back(c);
 }
 std::stringstream ss(sanitized);
 std::string item;
 while (std::getline(ss, item, ',')) {
 if (!item.empty()) {
 item.erase(0, item.find\_first\_not\_of(" \\t"));
 item.erase(item.find\_last\_not\_of(" \\t") + 1);
 if (!item.empty()) layer\_types.push\_back(item);
 }
 }
 }
 else if (key == "enc\_hidden\_act") encoder\_act\_gelu = (value == "gelu");
 else if (key == "dec\_hidden\_act") decoder\_act\_gelu = (value == "gelu");
 else if (key == "num\_encoder\_layers") num\_encoder\_layers = static\_cast(std::stoul(value));
 else if (key == "num\_decoder\_layers") num\_decoder\_layers = static\_cast(std::stoul(value));
 else if (key == "partial\_rotary\_factor") partial\_rotary\_factor = std::stof(value);
 else if (key == "pad\_token\_id") pad\_token\_id = static\_cast(std::stoul(value));
 else if (key == "conv\_kernel\_size") conv\_kernel\_size = static\_cast(std::stoul(value));
 else if (key == "subsampling\_conv\_kernel\_size") subsampling\_conv\_kernel\_size = static\_cast(std::stoul(value));
 else if (key == "subsampling\_conv\_stride") subsampling\_conv\_stride = static\_cast(std::stoul(value));
 else if (key == "subsampling\_conv\_channels") subsampling\_conv\_channels = static\_cast(std::stoul(value));
 else if (key == "subsampling\_factor") subsampling\_factor = static\_cast(std::stoul(value));
 else if (key == "num\_mel\_bins") num\_mel\_bins = static\_cast(std::stoul(value));
 else if (key == "encoder\_hidden\_act") encoder\_hidden\_act = value;
 else if (key == "linear\_num\_key\_heads") linear\_num\_key\_heads = static\_cast(std::stoul(value));
 else if (key == "linear\_key\_head\_dim") linear\_key\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "linear\_num\_value\_heads") linear\_num\_value\_heads = static\_cast(std::stoul(value));
 else if (key == "linear\_value\_head\_dim") linear\_value\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "linear\_q\_proj\_dim") linear\_q\_proj\_dim = static\_cast(std::stoul(value));
 else if (key == "kv\_lora\_rank") kv\_lora\_rank = static\_cast(std::stoul(value));
 else if (key == "q\_lora\_rank") q\_lora\_rank = static\_cast(std::stoul(value));
 else if (key == "qk\_head\_dim") qk\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "qk\_nope\_head\_dim") qk\_nope\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "qk\_rope\_head\_dim") qk\_rope\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "v\_head\_dim") v\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "rope\_interleave") rope\_interleave = (value == "true" \|\| value == "1");
 else if (key == "attention\_bias") attention\_bias = (value == "true" \|\| value == "1");
 else if (key == "rope\_scaling\_factor") rope\_scaling\_factor = std::stof(value);
 else if (key == "rope\_mscale\_all\_dim") rope\_mscale\_all\_dim = std::stof(value);
 else if (key == "linear\_k\_proj\_dim") linear\_k\_proj\_dim = static\_cast(std::stoul(value));
 else if (key == "linear\_v\_proj\_dim") linear\_v\_proj\_dim = static\_cast(std::stoul(value));
 else if (key == "predictor\_hidden\_dim") predictor\_hidden\_dim = static\_cast(std::stoul(value));
 else if (key == "predictor\_num\_layers") predictor\_num\_layers = static\_cast(std::stoul(value));
 else if (key == "tdt\_joint\_dim") tdt\_joint\_dim = static\_cast(std::stoul(value));
 else if (key == "tdt\_num\_durations") tdt\_num\_durations = static\_cast(std::stoul(value));
 else if (key == "tdt\_blank\_id") tdt\_blank\_id = static\_cast(std::stoul(value));
 else if (key == "tdt\_durations") {
 tdt\_durations.clear();
 std::stringstream ss(value);
 std::string item;
 while (std::getline(ss, item, ',')) {
 size\_t first = item.find\_first\_not\_of(" \\t");
 if (first == std::string::npos) continue;
 size\_t last = item.find\_last\_not\_of(" \\t");
 item = item.substr(first, last - first + 1);
 tdt\_durations.push\_back(static\_cast(std::stoul(item)));
 }
 }
 else if (key == "altup\_num\_inputs") altup\_num\_inputs = static\_cast(std::stoul(value));
 else if (key == "laurel\_rank") laurel\_rank = static\_cast(std::stoul(value));
 else if (key == "hidden\_size\_per\_layer\_input") hidden\_size\_per\_layer\_input = static\_cast(std::stoul(value));
 else if (key == "num\_kv\_shared\_layers") num\_kv\_shared\_layers = static\_cast(std::stoul(value));
 else if (key == "sliding\_window") sliding\_window = static\_cast(std::stoul(value));
 else if (key == "rope\_local\_base\_freq") rope\_local\_base\_freq = std::stof(value);
 else if (key == "final\_logit\_softcapping") final\_logit\_softcapping = std::stof(value);
 else if (key == "global\_partial\_rotary\_factor") global\_partial\_rotary\_factor = std::stof(value);
 else if (key == "expert\_intermediate\_size") expert\_intermediate\_size = static\_cast(std::stoul(value));
 else if (key == "global\_head\_dim") global\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "num\_global\_kv\_heads" \|\| key == "num\_global\_key\_value\_heads") num\_global\_kv\_heads = static\_cast(std::stoul(value));
 else if (key == "attention\_k\_eq\_v") attention\_k\_eq\_v = (value == "true" \|\| value == "1");
 else if (key == "enable\_moe\_block") enable\_moe\_block = (value == "true" \|\| value == "1");
 else if (key == "vision\_head\_dim") vision\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "vision\_kv\_heads") vision\_kv\_heads = static\_cast(std::stoul(value));
 else if (key == "vision\_intermediate\_size") vision\_intermediate\_size = static\_cast(std::stoul(value));
 else if (key == "vision\_position\_embedding\_size") vision\_position\_embedding\_size = static\_cast(std::stoul(value));
 else if (key == "vision\_pooling\_kernel\_size") vision\_pooling\_kernel\_size = static\_cast(std::stoul(value));
 else if (key == "vision\_default\_output\_length") vision\_default\_output\_length = static\_cast(std::stoul(value));
 else if (key == "vision\_rope\_theta") vision\_rope\_theta = std::stof(value);
 else if (key == "audio\_hidden\_dim") audio\_hidden\_dim = static\_cast(std::stoul(value));
 else if (key == "audio\_num\_layers") audio\_num\_layers = static\_cast(std::stoul(value));
 else if (key == "audio\_num\_heads") audio\_num\_heads = static\_cast(std::stoul(value));
 else if (key == "audio\_head\_dim") audio\_head\_dim = static\_cast(std::stoul(value));
 else if (key == "audio\_input\_feat\_size") audio\_input\_feat\_size = static\_cast(std::stoul(value));
 else if (key == "audio\_conf\_conv\_kernel\_size") audio\_conf\_conv\_kernel\_size = static\_cast(std::stoul(value));
 else if (key == "audio\_chunk\_size") audio\_chunk\_size = static\_cast(std::stoul(value));
 else if (key == "audio\_context\_left") audio\_context\_left = static\_cast(std::stoul(value));
 else if (key == "audio\_context\_right") audio\_context\_right = static\_cast(std::stoul(value));
 else if (key == "audio\_logit\_cap") audio\_logit\_cap = std::stof(value);
 else if (key == "audio\_residual\_weight") audio\_residual\_weight = std::stof(value);
 else if (key == "audio\_output\_proj\_dims") audio\_output\_proj\_dims = static\_cast(std::stoul(value));
 else if (key == "audio\_vocab\_size") audio\_vocab\_size = static\_cast(std::stoul(value));
 else if (key == "audio\_vocab\_offset") audio\_vocab\_offset = static\_cast(std::stoul(value));
 else if (key == "audio\_soft\_tokens") audio\_soft\_tokens = static\_cast(std::stoul(value));
 else if (key == "audio\_sscp\_conv0\_channels") audio\_sscp\_conv0\_channels = static\_cast(std::stoul(value));
 else if (key == "audio\_sscp\_conv1\_channels") audio\_sscp\_conv1\_channels = static\_cast(std::stoul(value));
 else if (key == "audio\_sscp\_conv\_eps") audio\_sscp\_conv\_eps = std::stof(value);
 else if (key == "audio\_rms\_norm\_eps") audio\_rms\_norm\_eps = std::stof(value);
 else if (key == "audio\_fft\_length") audio\_fft\_length = static\_cast(std::stoul(value));
 else if (key == "audio\_fft\_overdrive") {
 audio\_fft\_overdrive = (value == "true" \|\| value == "1");
 audio\_fft\_length = audio\_fft\_overdrive ? 1024u : 512u;
 }
 else if (key == "audio\_token\_id") audio\_token\_id = static\_cast(std::stoul(value));
 else if (key == "channel\_open\_token\_id") channel\_open\_token\_id = static\_cast(std::stoul(value));
 else if (key == "channel\_close\_token\_id") channel\_close\_token\_id = static\_cast(std::stoul(value));
 else if (key == "activation\_sparsity\_ppf") {
 activation\_sparsity\_ppf.clear();
 std::stringstream ss(value);
 std::string item;
 while (std::getline(ss, item, ',')) {
 size\_t first = item.find\_first\_not\_of(" \\t");
 if (first == std::string::npos) continue;
 size\_t last = item.find\_last\_not\_of(" \\t");
 item = item.substr(first, last - first + 1);
 activation\_sparsity\_ppf.push\_back(std::stof(item));
 }
 }
 }

 if (is\_gemma\_family(model\_type)) {
 default\_temperature = 1.0f;
 default\_top\_p = 0.95f;
 default\_top\_k = 64;
 if (model\_type == ModelType::GEMMA4) {
 default\_cloud\_handoff\_threshold = 0.92f;
 default\_rolling\_entropy\_window = 16;
 }
 } else if (model\_type == ModelType::LFM2) {
 default\_temperature = 0.3f;
 default\_top\_p = 0.95f;
 default\_top\_k = 20;
 } else if (model\_type == ModelType::QWEN) {
 default\_temperature = 0.6f;
 default\_top\_p = 0.95f;
 default\_top\_k = 20;
 } else if (model\_type == ModelType::QWEN3P5) {
 default\_temperature = 0.7f;
 default\_top\_p = 0.8f;
 default\_top\_k = 20;
 }

 if (model\_type == ModelType::GEMMA4) {
 auto missing\_u32 = \[\](uint32\_t v) { return v == UNSET\_U32; };
 auto missing\_f32 = \[\](float v) { return v == UNSET\_F32; };
 std::string missing;
 if (missing\_u32(hidden\_size\_per\_layer\_input)) missing += " hidden\_size\_per\_layer\_input";
 if (missing\_u32(num\_kv\_shared\_layers)) missing += " num\_kv\_shared\_layers";
 if (missing\_u32(sliding\_window)) missing += " sliding\_window";
 if (missing\_u32(global\_head\_dim)) missing += " global\_head\_dim";
 if (missing\_f32(rope\_local\_base\_freq)) missing += " rope\_local\_base\_freq";
 if (missing\_f32(final\_logit\_softcapping)) missing += " final\_logit\_softcapping";
 if (missing\_f32(global\_partial\_rotary\_factor)) missing += " global\_partial\_rotary\_factor";
 if (layer\_types.empty()) missing += " layer\_types";
 if (!missing.empty()) {
 CACTUS\_LOG\_ERROR("config", "Gemma4 config missing required fields:" << missing);
 return false;
 }
 }

 return true;
}

std::string Config::to\_json() const {
 return "{}";
}

std::unique\_ptr create\_model(const std::string& model\_folder) {
 CACTUS\_LOG\_DEBUG("model", "Creating model from: " << model\_folder);
 Config config;
 std::string config\_path = model\_folder + "/config.txt";

 if (!config.from\_json(config\_path)) {
 CACTUS\_LOG\_ERROR("model", "Failed to create model - cannot load config from: " << model\_folder);
 return nullptr;
 }

 const bool has\_vision\_support =
 config.use\_image\_tokens \|\|
 config.vision\_num\_layers > 0 \|\|
 config.vision\_embed\_dim > 0 \|\|
 config.vision\_hidden\_dim > 0 \|\|
 config.visual\_tokens\_per\_img > 0;

 const bool has\_audio\_support =
 config.audio\_num\_layers > 0 \|\|
 config.audio\_hidden\_dim > 0;

 if (config.model\_type == Config::ModelType::LFM2 && has\_vision\_support) {
 return std::make\_unique(config);
 }

 if (config.model\_type == Config::ModelType::GEMMA4 && (has\_vision\_support \|\| has\_audio\_support)) {
 return std::make\_unique(config);
 }

 switch (config.model\_type) {
 case Config::ModelType::QWEN:
 return std::make\_unique(config);
 case Config::ModelType::LFM2:
 return std::make\_unique(config);
 case Config::ModelType::GEMMA4:
 return std::make\_unique(config);
 default:
 return std::make\_unique(config);
 }
}

void Model::capture\_debug\_node(uint32\_t layer\_idx, const std::string& name, size\_t node\_id) const {
 auto\* graph = static\_cast(graph\_handle\_);
 if (!graph) {
 return;
 }
 graph->capture\_debug\_node(layer\_idx, name, node\_id);
}

void Model::clear\_debug\_nodes() {
 auto\* graph = static\_cast(graph\_handle\_);
 if (!graph) {
 return;
 }
 graph->clear\_debug\_nodes();
}

const std::vector& Model::get\_debug\_nodes() const {
 auto\* graph = static\_cast(graph\_handle\_);
 debug\_nodes\_.clear();
 if (!graph) {
 return debug\_nodes\_;
 }

 const auto& entries = graph->get\_debug\_nodes();
 debug\_nodes\_.reserve(entries.size());
 for (const auto& entry : entries) {
 debug\_nodes\_.push\_back({entry.layer\_idx, entry.name, entry.node\_id});
 }
 return debug\_nodes\_;
}

bool Model::load\_npu\_prefill(const std::string& model\_path) {
 CACTUS\_LOG\_DEBUG("npu", "Attempting to load NPU prefill from: " << model\_path);

 npu\_prefill\_ = npu::create\_prefill();
 if (!npu\_prefill\_) {
 CACTUS\_LOG\_DEBUG("npu", "NPU prefill creation failed (not supported on this device)");
 return false;
 }

 bool loaded = npu\_prefill\_->load(model\_path);
 if (loaded) {
 CACTUS\_LOG\_INFO("npu", "NPU prefill loaded successfully from: " << model\_path);
 } else {
 CACTUS\_LOG\_DEBUG("npu", "NPU prefill model not found at: " << model\_path);
 }
 return loaded;
}

bool Model::has\_npu\_prefill() const {
 return npu\_prefill\_ && npu\_prefill\_->is\_available();
}

size\_t Model::get\_prefill\_chunk\_size() const {
 if (has\_npu\_prefill()) {
 return static\_cast(npu\_prefill\_->get\_chunk\_size());
 }
 return 256; // default chunk size
}

std::vector<\_\_fp16> Model::get\_token\_embeddings(const std::vector& tokens) {
 auto\* gb = static\_cast(graph\_handle\_);
 if (!gb \|\| tokens.empty()) {
 return {};
 }

 gb->soft\_reset();

 size\_t tok\_input = gb->input({tokens.size()}, Precision::FP32);
 std::vector tok\_f(tokens.size());
 for (size\_t i = 0; i < tokens.size(); i++) {
 tok\_f\[i\] = static\_cast(tokens\[i\]);
 }
 gb->set\_input(tok\_input, tok\_f.data(), Precision::FP32);

 size\_t embedding\_node = gb->embedding(embedding\_node\_id\_, tok\_input);

 gb->execute();

 const auto& emb\_buf = gb->get\_output\_buffer(embedding\_node);
 void\* emb\_ptr = gb->get\_output(embedding\_node);

 size\_t num\_tokens = tokens.size();
 size\_t hidden\_dim = config\_.hidden\_dim;
 std::vector<\_\_fp16> embeddings(num\_tokens \* hidden\_dim);

 if (emb\_buf.precision == Precision::FP16) {
 \_\_fp16\* src = static\_cast<\_\_fp16\*>(emb\_ptr);
 std::copy(src, src + num\_tokens \* hidden\_dim, embeddings.begin());
 } else if (emb\_buf.precision == Precision::FP32) {
 float\* src = static\_cast(emb\_ptr);
 for (size\_t i = 0; i < num\_tokens \* hidden\_dim; i++) {
 embeddings\[i\] = static\_cast<\_\_fp16>(src\[i\]);
 }
 } else if (emb\_buf.precision == Precision::INT8) {
 int8\_t\* src = static\_cast(emb\_ptr);
 for (size\_t i = 0; i < num\_tokens \* hidden\_dim; i++) {
 embeddings\[i\] = static\_cast<\_\_fp16>(src\[i\]);
 }
 }

 return embeddings;
}

void Model::prefill\_npu(const std::vector& tokens) {
 if (!npu\_prefill\_ \|\| !npu\_prefill\_->is\_available()) {
 throw std::runtime\_error("NPU prefill not available");
 }

 auto\* gb = static\_cast(graph\_handle\_);
 const int chunk\_size = npu\_prefill\_->get\_chunk\_size();
 const int hidden\_dim = npu\_prefill\_->get\_hidden\_dim();
 const int num\_layers = npu\_prefill\_->get\_num\_layers();
 const int fallback\_num\_kv\_heads = npu\_prefill\_->get\_num\_kv\_heads();
 const int fallback\_head\_dim = npu\_prefill\_->get\_head\_dim();

 const std::vector layer\_dims = get\_kv\_layer\_dims();
 const std::vector layer\_heads = get\_kv\_layer\_heads();
 const int layers\_to\_update = std::min(num\_layers, static\_cast(config\_.num\_layers));

 std::vector<\_\_fp16> all\_embeddings = get\_token\_embeddings(tokens);
 if (all\_embeddings.empty()) {
 throw std::runtime\_error("Failed to get token embeddings for NPU prefill");
 }

 if (Config::is\_gemma\_family(config\_.model\_type)) {
 float scale = std::sqrt(static\_cast(hidden\_dim));
 for (size\_t i = 0; i < all\_embeddings.size(); i++) {
 all\_embeddings\[i\] = \_\_fp16(static\_cast(all\_embeddings\[i\]) \* scale);
 }
 }

 size\_t num\_tokens = tokens.size();
 size\_t num\_chunks = (num\_tokens + chunk\_size - 1) / chunk\_size;

 for (size\_t c = 0; c < num\_chunks; c++) {
 size\_t start = c \* chunk\_size;
 size\_t actual\_tokens = std::min(static\_cast(chunk\_size), num\_tokens - start);

 std::vector<\_\_fp16> chunk\_embeddings(chunk\_size \* hidden\_dim, \_\_fp16(0));
 std::copy(all\_embeddings.begin() + start \* hidden\_dim,
 all\_embeddings.begin() + (start + actual\_tokens) \* hidden\_dim,
 chunk\_embeddings.begin());

 int position\_offset = static\_cast(start);

 npu::NPUPrefillDirectResult direct\_result = npu\_prefill\_->prefill\_chunk\_direct(chunk\_embeddings, position\_offset);

 if (direct\_result.valid) {
 gb->soft\_reset\_keep\_pool();
 for (int layer\_idx = 0; layer\_idx < layers\_to\_update; layer\_idx++) {
 const auto& k\_ref = direct\_result.k\_caches\[layer\_idx\];
 const auto& v\_ref = direct\_result.v\_caches\[layer\_idx\];

 if (k\_ref.data && v\_ref.data && graph\_cache\_k\_nodes\_\[layer\_idx\] != 0) {
 size\_t layer\_kv\_heads = layer\_idx < static\_cast(layer\_heads.size())
 ? layer\_heads\[layer\_idx\]
 : static\_cast(fallback\_num\_kv\_heads);
 size\_t layer\_head\_dim = layer\_idx < static\_cast(layer\_dims.size())
 ? layer\_dims\[layer\_idx\]
 : static\_cast(fallback\_head\_dim);

 size\_t expected = static\_cast(chunk\_size) \* layer\_kv\_heads \* layer\_head\_dim;
 if (expected > 0 && (k\_ref.count < expected \|\| v\_ref.count < expected)) {
 CACTUS\_LOG\_WARN(
 "npu",
 "NPU prefill cache output too small for layer " << layer\_idx
 << " (expected>=" << expected
 << ", got k=" << k\_ref.count << ", v=" << v\_ref.count << "); skipping layer");
 continue;
 }

 size\_t kv\_elements = actual\_tokens \* layer\_kv\_heads \* layer\_head\_dim;
 size\_t k\_input = gb->input({kv\_elements}, Precision::FP16);
 gb->set\_external\_input(k\_input, const\_cast<\_\_fp16\*>(k\_ref.data), Precision::FP16);
 size\_t v\_input = gb->input({kv\_elements}, Precision::FP16);
 gb->set\_external\_input(v\_input, const\_cast<\_\_fp16\*>(v\_ref.data), Precision::FP16);

 size\_t layer\_window = get\_kv\_layer\_windows()\[layer\_idx\];
 gb->kv\_cache\_append(k\_input, graph\_cache\_k\_nodes\_\[layer\_idx\], layer\_window, cache\_sink\_size\_);
 gb->kv\_cache\_append(v\_input, graph\_cache\_v\_nodes\_\[layer\_idx\], layer\_window, cache\_sink\_size\_);
 }
 }
 gb->execute();
 cache\_total\_seq\_len\_ += actual\_tokens;
 }
 }
}

double Model::score\_tokens\_window\_logprob(
 const std::vector& tokens,
 size\_t start,
 size\_t end,
 size\_t context,
 size\_t\* tokens\_scored
) {
 if (tokens\_scored)
 \*tokens\_scored = 0;

 if (tokens.empty())
 return 0.0;

 if (end > tokens.size())
 end = tokens.size();

 if (start >= end)
 return 0.0;

 if (start == 0)
 start = 1;

 if (start >= end)
 return 0.0;

 const size\_t target\_len = end - start;
 const size\_t ctx\_begin = (start > context) ? (start - context) : 0;

 if (end < 2) return 0.0;
 const size\_t input\_end = end - 1;

 if (input\_end <= ctx\_begin)
 return 0.0;

 std::vector input\_tokens(tokens.begin() + ctx\_begin,tokens.begin() + input\_end);

 if (tokens\_scored)
 \*tokens\_scored = target\_len;

 reset\_cache();

 auto\* gb = static\_cast(graph\_handle\_);
 const auto backend = (config\_.default\_backend == Config::Backend::CPU) ? ComputeBackend::CPU : ComputeBackend::NPU;

 const size\_t hidden\_node = forward(input\_tokens, /\*use\_cache=\*/false);
 const auto& hidden\_buf = gb->get\_output\_buffer(hidden\_node);

 if (hidden\_buf.shape.size() != 2) {
 throw std::runtime\_error("Expected hidden to be rank-2 \[L, hidden\_dim\]");
 }

 const size\_t first\_pos = start - ctx\_begin - 1;
 const size\_t hidden\_slice = gb->slice(hidden\_node, /\*axis=\*/0, first\_pos, target\_len);
 bool transpose\_w = true;
 const size\_t logits\_node = gb->matmul(hidden\_slice, output\_weight\_node\_id\_, transpose\_w, backend);
 gb->execute();

 const auto& logits\_buf = gb->get\_output\_buffer(logits\_node);
 if (logits\_buf.shape.size() != 2)
 throw std::runtime\_error("Expected logits to be rank-2 \[T, vocab\]");

 const size\_t T = logits\_buf.shape\[0\];
 const size\_t vocab\_size = logits\_buf.shape\[1\];

 if (T != target\_len)
 throw std::runtime\_error("Logits T dimension does not match target\_len");

 void\* logits\_ptr = gb->get\_output(logits\_node);
 std::vector row(vocab\_size);
 double total\_logprob = 0.0;

 for (size\_t i = 0; i < target\_len; ++i) {
 const uint32\_t y = tokens\[start + i\];
 if (y >= vocab\_size)
 throw std::runtime\_error("Target token out of vocab range");

 if (logits\_buf.precision == Precision::FP32) {
 const float\* src = static\_cast(logits\_ptr) + i \* vocab\_size;
 std::memcpy(row.data(), src, vocab\_size \* sizeof(float));
 }
 else if (logits\_buf.precision == Precision::FP16) {
 const \_\_fp16\* src = static\_cast(logits\_ptr) + i \* vocab\_size;
 Quantization::fp16\_to\_fp32(const\_cast<\_\_fp16\*>(src), row.data(), vocab\_size);
 }
 else {
 const int8\_t\* src = static\_cast(logits\_ptr) + i \* vocab\_size;
 Quantization::int8\_to\_fp32(const\_cast(src), row.data(), vocab\_size, 1.0f);
 }

 float max\_logit = \*std::max\_element(row.begin(), row.end());
 double sum = 0.0;

 for (size\_t j = 0; j < vocab\_size; ++j)
 sum += std::exp(double(row\[j\] - max\_logit));

 const double lse = double(max\_logit) + std::log(sum);
 total\_logprob += double(row\[y\]) - lse;
 }

 return total\_logprob;
}
}
}