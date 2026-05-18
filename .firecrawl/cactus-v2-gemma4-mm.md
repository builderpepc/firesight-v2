#include "model\_gemma4.h"
#include "cactus\_graph.h"
#include
#include
#include

namespace cactus {
namespace engine {

Gemma4MmModel::Gemma4MmModel() : Model() {
 config\_.model\_type = Config::ModelType::GEMMA4;
}

Gemma4MmModel::Gemma4MmModel(const Config& config)
 : Model(config), vision\_encoder\_(config), audio\_encoder\_(config), language\_model\_(config) {}

bool Gemma4MmModel::init(const std::string& model\_folder, size\_t context\_size,
 const std::string& system\_prompt, bool do\_warmup) {
 if (!Model::init(model\_folder, context\_size, system\_prompt, false))
 return false;

 auto\* shared\_graph = static\_cast(graph\_handle\_);
 if (!shared\_graph)
 throw std::runtime\_error("Shared graph was not initialized for Gemma4MmModel");

 bool has\_vision = config\_.vision\_num\_layers > 0 \|\| config\_.vision\_embed\_dim > 0;
 bool has\_audio = config\_.audio\_num\_layers > 0 \|\| config\_.audio\_hidden\_dim > 0;

 if (has\_vision) {
 if (!vision\_encoder\_.init(shared\_graph, model\_folder, context\_size, "", false))
 throw std::runtime\_error("Failed to initialize vision encoder");
 }

 if (has\_audio) {
 if (!audio\_encoder\_.init(shared\_graph, model\_folder, context\_size, "", false))
 throw std::runtime\_error("Failed to initialize audio encoder");
 }

 if (!language\_model\_.init(shared\_graph, model\_folder, context\_size, system\_prompt, false))
 throw std::runtime\_error("Failed to initialize language model");

 output\_weight\_node\_id\_ = language\_model\_.output\_weight\_node\_id\_;

 if (do\_warmup) {
 std::vector warmup\_tokens = {2};
 language\_model\_.forward(warmup\_tokens);
 auto\* gb2 = static\_cast(language\_model\_.graph\_handle\_);
 gb2->execute();
 language\_model\_.reset\_cache();
 }

 return true;
}

void Gemma4MmModel::reset\_cache() {
 Model::reset\_cache();
 language\_model\_.reset\_cache();
}

void Gemma4MmModel::compact\_kv\_cache() {
 language\_model\_.compact\_kv\_cache();
}

void Gemma4MmModel::remove\_thinking\_tokens(const std::vector>& ranges) {
 language\_model\_.remove\_thinking\_tokens(ranges);
}

void Gemma4MmModel::set\_tool\_constraints(const std::vector& tools) {
 language\_model\_.set\_tool\_constraints(tools);
}

void Gemma4MmModel::clear\_tool\_constraints() {
 language\_model\_.clear\_tool\_constraints();
}

void Gemma4MmModel::update\_tool\_constraints(uint32\_t token\_id) {
 language\_model\_.update\_tool\_constraints(token\_id);
}

void Gemma4MmModel::load\_weights\_to\_graph(CactusGraph\*) {
 output\_weight\_node\_id\_ = 0;
}

Gemma4MmModel::ForwardResult Gemma4MmModel::forward\_multimodal(
 CactusGraph\* gb, const std::vector& tokens,
 const std::vector& image\_paths,
 const std::vector\\* audio\_features,
 size\_t audio\_num\_frames,
 ComputeBackend backend, bool use\_cache) {

 auto inputs = build\_multimodal\_inputs(
 gb, tokens, image\_paths, audio\_features, audio\_num\_frames, backend);

 size\_t final\_hidden = language\_model\_.forward\_from\_embeddings(
 gb,
 inputs.hidden\_node,
 inputs.pli\_hidden\_source\_node,
 inputs.pli\_tokens,
 inputs.seq\_len,
 backend,
 use\_cache);

 return ForwardResult{final\_hidden, inputs.seq\_len};
}

Gemma4MmModel::MultimodalInputs Gemma4MmModel::build\_multimodal\_inputs(
 CactusGraph\* gb, const std::vector& tokens,
 const std::vector& image\_paths,
 const std::vector\\* audio\_features,
 size\_t audio\_num\_frames,
 ComputeBackend backend) {

 size\_t vision\_soft\_node = 0;
 size\_t num\_vision\_soft\_tokens = 0;
 size\_t audio\_soft\_node = 0;
 size\_t num\_audio\_soft\_tokens = 0;

 if (!image\_paths.empty()) {
 auto preprocessed = vision\_encoder\_.preprocess\_image(image\_paths\[0\]);
 size\_t vision\_output = vision\_encoder\_.forward\_vision(gb, preprocessed, backend);
 vision\_soft\_node = vision\_encoder\_.build\_vision\_projector(gb, vision\_output, backend);
 uint32\_t k = config\_.vision\_pooling\_kernel\_size;
 num\_vision\_soft\_tokens = (preprocessed.patch\_width / k) \* (preprocessed.patch\_height / k);
 }

 if (audio\_features && !audio\_features->empty()) {
 size\_t audio\_output = audio\_encoder\_.forward\_audio(gb, \*audio\_features, audio\_num\_frames, backend);
 audio\_soft\_node = audio\_encoder\_.build\_audio\_projector(gb, audio\_output, backend);
 const auto& audio\_buf = gb->get\_output\_buffer(audio\_soft\_node);
 num\_audio\_soft\_tokens = audio\_buf.shape\[0\];
 }

 uint32\_t image\_token\_id = config\_.image\_token\_id;
 uint32\_t audio\_token\_id = config\_.audio\_token\_id;
 uint32\_t pad\_token\_id = config\_.pad\_token\_id;

 std::vector sequence\_nodes;
 std::vector current\_text;
 std::vector pli\_tokens;
 size\_t total\_seq\_len = 0;
 size\_t vision\_offset = 0;
 size\_t audio\_offset = 0;

 auto flush\_text = \[&\]() {
 if (current\_text.empty()) return;
 size\_t seg\_len = current\_text.size();
 size\_t input\_node = gb->input({seg\_len}, Precision::FP32);

 auto hidden = gb->scalar\_multiply(
 gb->embedding(language\_model\_.embedding\_node\_id\_, input\_node),
 std::sqrt(static\_cast(config\_.hidden\_dim)));

 std::vector input\_data(seg\_len);
 for (size\_t i = 0; i < seg\_len; i++)
 input\_data\[i\] = static\_cast(current\_text\[i\]);
 gb->set\_input(input\_node, input\_data.data(), Precision::FP32);

 sequence\_nodes.push\_back(hidden);
 for (auto t : current\_text)
 pli\_tokens.push\_back(t);
 total\_seq\_len += seg\_len;
 current\_text.clear();
 };

 auto append\_soft\_region = \[&\](size\_t soft\_node, size\_t& soft\_offset, size\_t total\_soft\_tokens,
 size\_t placeholder\_count) {
 size\_t to\_insert = std::min(placeholder\_count, total\_soft\_tokens - soft\_offset);
 if (to\_insert > 0) {
 sequence\_nodes.push\_back(gb->slice(soft\_node, 0, soft\_offset, to\_insert));
 for (size\_t j = 0; j < to\_insert; j++)
 pli\_tokens.push\_back(pad\_token\_id);
 total\_seq\_len += to\_insert;
 soft\_offset += to\_insert;
 }
 };

 auto flush\_vision\_region = \[&\](size\_t placeholder\_count) {
 append\_soft\_region(vision\_soft\_node, vision\_offset, num\_vision\_soft\_tokens, placeholder\_count);
 };

 auto flush\_audio\_region = \[&\](size\_t placeholder\_count) {
 append\_soft\_region(audio\_soft\_node, audio\_offset, num\_audio\_soft\_tokens, placeholder\_count);
 };

 bool in\_image\_region = false;
 bool in\_audio\_region = false;
 size\_t region\_count = 0;

 for (size\_t i = 0; i < tokens.size(); i++) {
 uint32\_t tok = tokens\[i\];
 bool is\_vision\_token = (tok == image\_token\_id && image\_token\_id != 0);
 bool is\_audio\_token = (tok == audio\_token\_id && audio\_token\_id != 0);

 if (is\_vision\_token) {
 if (in\_audio\_region) {
 flush\_audio\_region(region\_count);
 in\_audio\_region = false;
 }
 if (!in\_image\_region) {
 flush\_text();
 in\_image\_region = true;
 region\_count = 0;
 }
 region\_count++;
 } else if (is\_audio\_token) {
 if (in\_image\_region) {
 flush\_vision\_region(region\_count);
 in\_image\_region = false;
 }
 if (!in\_audio\_region) {
 flush\_text();
 in\_audio\_region = true;
 region\_count = 0;
 }
 region\_count++;
 } else {
 if (in\_image\_region) {
 flush\_vision\_region(region\_count);
 in\_image\_region = false;
 }
 if (in\_audio\_region) {
 flush\_audio\_region(region\_count);
 in\_audio\_region = false;
 }
 current\_text.push\_back(tok);
 }
 }

 if (in\_image\_region)
 flush\_vision\_region(region\_count);
 if (in\_audio\_region)
 flush\_audio\_region(region\_count);
 flush\_text();

 if (sequence\_nodes.empty())
 throw std::runtime\_error("No embedding nodes built");

 size\_t merged = sequence\_nodes\[0\];
 for (size\_t i = 1; i < sequence\_nodes.size(); i++)
 merged = gb->concat(merged, sequence\_nodes\[i\], 0);

 return MultimodalInputs{
 .hidden\_node = merged,
 .pli\_hidden\_source\_node = merged,
 .pli\_tokens = std::move(pli\_tokens),
 .seq\_len = total\_seq\_len,
 };
}

uint32\_t Gemma4MmModel::decode\_multimodal(
 const std::vector& tokens,
 const std::vector& image\_paths,
 const std::vector\\* audio\_features,
 size\_t audio\_num\_frames,
 float temperature, float top\_p, size\_t top\_k,
 const std::string& profile\_file, float\* out\_entropy,
 float min\_p, float repetition\_penalty) {

 if (!initialized\_ \|\| !graph\_handle\_)
 throw std::runtime\_error("Model not initialized - call init() first");

 bool has\_media = !image\_paths.empty() \|\| (audio\_features && !audio\_features->empty());

 if (!has\_media) {
 return language\_model\_.decode(tokens, temperature, top\_p, top\_k, profile\_file, out\_entropy, min\_p, repetition\_penalty);
 }

 if (temperature < 0) temperature = config\_.default\_temperature;
 if (top\_p < 0) top\_p = config\_.default\_top\_p;
 if (top\_k == 0) top\_k = config\_.default\_top\_k;

 auto\* gb = static\_cast(graph\_handle\_);
 gb->soft\_reset();
 auto backend = config\_.default\_backend == Config::Backend::CPU ? ComputeBackend::CPU : ComputeBackend::NPU;

 size\_t cached\_len = language\_model\_.cache\_total\_seq\_len\_;
 if (cached\_len >= tokens.size()) {
 reset\_cache();
 cached\_len = 0;
 }
 std::vector forward\_tokens = cached\_len == 0
 ? tokens
 : std::vector(tokens.end() - (tokens.size() - cached\_len), tokens.end());

 bool delta\_has\_media = std::any\_of(forward\_tokens.begin(), forward\_tokens.end(), \[&\](uint32\_t t) {
 return (config\_.image\_token\_id != 0 && t == config\_.image\_token\_id) \|\|
 (config\_.audio\_token\_id != 0 && t == config\_.audio\_token\_id);
 });

 size\_t final\_hidden\_node = 0;
 size\_t seq\_len\_for\_updates = 0;
 if (delta\_has\_media) {
 auto result = forward\_multimodal(gb, forward\_tokens, image\_paths, audio\_features,
 audio\_num\_frames, backend, true);
 final\_hidden\_node = result.final\_hidden\_node;
 seq\_len\_for\_updates = result.seq\_len;
 } else {
 final\_hidden\_node = language\_model\_.forward(forward\_tokens, true);
 seq\_len\_for\_updates = forward\_tokens.size();
 }

 auto last\_hidden = gb->index(final\_hidden\_node, seq\_len\_for\_updates - 1, 0);
 const auto& last\_buf = gb->get\_output\_buffer(last\_hidden);
 last\_hidden = gb->reshape(last\_hidden, {1, last\_buf.shape\[0\]});

 auto logits\_node = gb->matmul(last\_hidden, language\_model\_.output\_weight\_node\_id\_, true, backend);

 if (config\_.final\_logit\_softcapping > 0.0f) {
 float inv\_cap = 1.0f / config\_.final\_logit\_softcapping;
 logits\_node = gb->scalar\_multiply(logits\_node, inv\_cap);
 logits\_node = gb->tanh(logits\_node);
 logits\_node = gb->scalar\_multiply(logits\_node, config\_.final\_logit\_softcapping);
 }

 size\_t sampled\_token =
 language\_model\_.sample\_token(gb, logits\_node, temperature, top\_p, top\_k, min\_p, repetition\_penalty, nullptr);

 if (!profile\_file.empty())
 gb->execute(profile\_file);
 else
 gb->execute();

 compute\_entropy(gb, logits\_node, out\_entropy);

 language\_model\_.post\_execute\_updates(gb, seq\_len\_for\_updates);
 language\_model\_.cache\_total\_seq\_len\_ += seq\_len\_for\_updates;

 auto\* output\_ptr = gb->get\_output(sampled\_token);
 uint32\_t result\_token = \*static\_cast(output\_ptr);
 language\_model\_.record\_sampled\_token(result\_token);
 return result\_token;
}

size\_t Gemma4MmModel::forward(const std::vector& tokens, bool use\_cache) {
 return language\_model\_.forward(tokens, use\_cache);
}

uint32\_t Gemma4MmModel::decode(const std::vector& tokens,
 float temperature, float top\_p, size\_t top\_k,
 const std::string& profile\_file, float\* out\_entropy,
 float min\_p, float repetition\_penalty) {
 if (!initialized\_ \|\| !graph\_handle\_)
 throw std::runtime\_error("Model not initialized - call init() first");
 return language\_model\_.decode(tokens, temperature, top\_p, top\_k, profile\_file, out\_entropy, min\_p, repetition\_penalty);
}

void Gemma4MmModel::prefill(const std::vector& tokens, size\_t chunk\_size,
 const std::string& profile\_file) {
 if (!initialized\_ \|\| !graph\_handle\_)
 throw std::runtime\_error("Model not initialized - call init() first");
 language\_model\_.prefill(tokens, chunk\_size, profile\_file);
}

void Gemma4MmModel::prefill\_with\_images(const std::vector& tokens,
 const std::vector& image\_paths,
 const std::string& profile\_file) {
 if (!initialized\_ \|\| !graph\_handle\_)
 throw std::runtime\_error("Model not initialized - call init() first");

 if (image\_paths.empty()) {
 prefill(tokens, get\_prefill\_chunk\_size(), profile\_file);
 return;
 }

 auto\* gb = static\_cast(graph\_handle\_);
 gb->soft\_reset();
 auto backend = config\_.default\_backend == Config::Backend::CPU ? ComputeBackend::CPU : ComputeBackend::NPU;

 auto result = forward\_multimodal(gb, tokens, image\_paths, nullptr, 0, backend, true);

 if (!profile\_file.empty())
 gb->execute(profile\_file);
 else
 gb->execute();

 language\_model\_.post\_execute\_updates(gb, result.seq\_len);
 language\_model\_.cache\_total\_seq\_len\_ += result.seq\_len;
}

uint32\_t Gemma4MmModel::decode\_with\_images(
 const std::vector& tokens, const std::vector& image\_paths,
 float temperature, float top\_p, size\_t top\_k,
 const std::string& profile\_file, float\* out\_entropy,
 float min\_p, float repetition\_penalty) {
 return decode\_multimodal(tokens, image\_paths, nullptr, 0,
 temperature, top\_p, top\_k, profile\_file, out\_entropy,
 min\_p, repetition\_penalty);
}

uint32\_t Gemma4MmModel::decode\_with\_audio(
 const std::vector& tokens, const std::vector& audio\_features,
 float temperature, float top\_p, size\_t top\_k,
 const std::string& profile\_file, float\* out\_entropy,
 float min\_p, float repetition\_penalty,
 float\* /\*out\_token\_time\_start\*/, float\* /\*out\_token\_time\_end\*/) {
 size\_t num\_frames = audio\_features.size() / config\_.audio\_input\_feat\_size;
 std::vector empty\_images;
 return decode\_multimodal(tokens, empty\_images, &audio\_features, num\_frames,
 temperature, top\_p, top\_k, profile\_file, out\_entropy,
 min\_p, repetition\_penalty);
}

uint32\_t Gemma4MmModel::decode\_with\_media(
 const std::vector& tokens,
 const std::vector& image\_paths,
 const std::vector& audio\_features,
 float temperature, float top\_p, size\_t top\_k,
 const std::string& profile\_file, float\* out\_entropy,
 float min\_p, float repetition\_penalty) {
 size\_t num\_frames = audio\_features.size() / config\_.audio\_input\_feat\_size;
 return decode\_multimodal(tokens, image\_paths, &audio\_features, num\_frames,
 temperature, top\_p, top\_k, profile\_file, out\_entropy,
 min\_p, repetition\_penalty);
}

std::vector Gemma4MmModel::get\_image\_embeddings(const std::string& image\_path) {
 if (!initialized\_ \|\| !graph\_handle\_)
 throw std::runtime\_error("Model not initialized - call init() first");
 auto\* gb = static\_cast(graph\_handle\_);
 gb->soft\_reset();
 auto backend = config\_.default\_backend == Config::Backend::CPU ? ComputeBackend::CPU : ComputeBackend::NPU;

 auto preprocessed = vision\_encoder\_.preprocess\_image(image\_path);
 size\_t vision\_output = vision\_encoder\_.forward\_vision(gb, preprocessed, backend);
 size\_t projected = vision\_encoder\_.build\_vision\_projector(gb, vision\_output, backend);

 gb->execute();

 const auto& buf = gb->get\_output\_buffer(projected);
 size\_t total = buf.total\_size;
 std::vector embedding(total);
 const \_\_fp16\* fp16\_data = buf.data\_as<\_\_fp16>();
 for (size\_t i = 0; i < total; i++)
 embedding\[i\] = static\_cast(fp16\_data\[i\]);
 return embedding;
}

std::vector Gemma4MmModel::get\_audio\_embeddings(const std::vector& audio\_features) {
 if (!initialized\_ \|\| !graph\_handle\_)
 throw std::runtime\_error("Model not initialized - call init() first");
 auto\* gb = static\_cast(graph\_handle\_);
 gb->soft\_reset();
 auto backend = config\_.default\_backend == Config::Backend::CPU ? ComputeBackend::CPU : ComputeBackend::NPU;

 size\_t num\_frames = audio\_features.size() / config\_.audio\_input\_feat\_size;
 size\_t audio\_output = audio\_encoder\_.forward\_audio(gb, audio\_features, num\_frames, backend);
 size\_t projected = audio\_encoder\_.build\_audio\_projector(gb, audio\_output, backend);

 gb->execute();

 const auto& buf = gb->get\_output\_buffer(projected);
 size\_t total = buf.total\_size;
 std::vector embedding(total);
 const \_\_fp16\* fp16\_data = buf.data\_as<\_\_fp16>();
 for (size\_t i = 0; i < total; i++)
 embedding\[i\] = static\_cast(fp16\_data\[i\]);
 return embedding;
}

size\_t Gemma4MmModel::build\_attention(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) {
 throw std::runtime\_error("build\_attention should not be called directly on Gemma4MmModel");
}

size\_t Gemma4MmModel::build\_mlp(CactusGraph\*, size\_t, uint32\_t, ComputeBackend) const {
 throw std::runtime\_error("build\_mlp should not be called directly on Gemma4MmModel");
}

size\_t Gemma4MmModel::build\_transformer\_block(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) {
 throw std::runtime\_error("build\_transformer\_block should not be called directly on Gemma4MmModel");
}

}
}