#pragma once

#include
#include
#include
#include
#include
#include

#include "cactus\_graph.h"

class CactusGraph;

namespace cactus {
namespace npu {

struct NPUNamedInput {
 std::string name;
 const \_\_fp16\* data;
 std::vector shape;
};

class NPUEncoder {
public:
 virtual ~NPUEncoder() = default;
 virtual bool load(const std::string& model\_path) = 0;
 virtual bool preallocate(
 const std::vector& input\_shape,
 const std::string& input\_name = "x",
 const std::string& output\_name = "") = 0;
 virtual size\_t encode(
 const \_\_fp16\* input, \_\_fp16\* output,
 const std::vector& shape,
 const std::string& input\_name = "x",
 const std::string& output\_name = "") = 0;
 virtual bool is\_available() const = 0;
 virtual std::vector get\_input\_shape() const = 0;
 virtual std::vector get\_output\_shape() const = 0;
 virtual \_\_fp16\* get\_output\_buffer() = 0;
 virtual size\_t get\_output\_buffer\_size() const = 0;
 virtual size\_t encode\_multimodal\_input(
 const std::vector& inputs,
 \_\_fp16\* output,
 const std::string& output\_name = "") = 0;
};

std::unique\_ptr create\_encoder();
bool is\_npu\_available();

struct NPUBufferRef {
 const \_\_fp16\* data;
 size\_t count;
};

struct NPUPrefillDirectResult {
 NPUBufferRef hidden;
 std::vector k\_caches;
 std::vector v\_caches;
 bool valid;
};

class NPUPrefill {
public:
 virtual ~NPUPrefill() = default;
 virtual bool load(const std::string& model\_path) = 0;
 virtual bool is\_available() const = 0;
 virtual int get\_chunk\_size() const = 0;
 virtual int get\_hidden\_dim() const = 0;
 virtual int get\_num\_layers() const = 0;
 virtual int get\_num\_kv\_heads() const = 0;
 virtual int get\_head\_dim() const = 0;
 virtual NPUPrefillDirectResult prefill\_chunk\_direct(
 const std::vector<\_\_fp16>& embeddings,
 int position\_offset = 0,
 const std::string& input\_name = "x") = 0;
};

std::unique\_ptr create\_prefill();

} // namespace npu
namespace engine {

struct Config {
 uint32\_t vocab\_size = 151936;
 uint32\_t bos\_token\_id = 151643;
 uint32\_t eos\_token\_id = 151645;
 uint32\_t num\_layers = 28;
 uint32\_t hidden\_dim = 1024;
 uint32\_t ffn\_intermediate\_dim = 3072;
 uint32\_t attention\_heads = 16;
 uint32\_t attention\_kv\_heads = 8;
 uint32\_t attention\_head\_dim = 128;
 float layer\_norm\_eps = 1e-6f;
 float rope\_theta = 1000000.0f;
 uint32\_t num\_experts = 0;
 uint32\_t num\_shared\_experts = 0;
 uint32\_t num\_top\_experts = 0;
 uint32\_t moe\_every\_n\_layers = 0;
 uint32\_t moe\_intermediate\_dim = 0;
 uint32\_t num\_dense\_layers = 0;
 uint32\_t num\_experts\_per\_tok = 0;
 bool norm\_topk\_prob = false;
 bool use\_expert\_bias = false;
 float routed\_scaling\_factor = 1.0f;
 bool tie\_word\_embeddings = true;

 uint32\_t vision\_hidden\_dim = 0;
 uint32\_t vision\_num\_layers = 0;
 uint32\_t vision\_attention\_heads = 0;
 uint32\_t vision\_image\_size = 0;
 uint32\_t vision\_patch\_size = 0;
 uint32\_t vision\_num\_channels = 3;
 uint32\_t vision\_embed\_dim = 0;
 uint32\_t visual\_tokens\_per\_img = 0;
 bool use\_pixel\_shuffle = false;
 uint32\_t pixel\_shuffle\_factor = 1;
 bool use\_image\_tokens = false;
 uint32\_t image\_token\_id = 0;
 bool use\_layout\_tags = false;
 uint32\_t image\_seq\_len = 64;

 uint32\_t global\_image\_size = 2048;
 uint32\_t max\_tile\_size = 512;
 float rescale\_factor = 0.00392156862745098f;
 float image\_mean = 0.5f;
 float image\_std = 0.5f;

 uint32\_t downsample\_factor = 2;
 uint32\_t min\_tiles = 2;
 uint32\_t max\_tiles = 10;
 bool use\_thumbnail = true;
 uint32\_t min\_image\_tokens = 64;
 uint32\_t max\_image\_tokens = 256;
 uint32\_t max\_num\_patches = 1024;
 uint32\_t tile\_size = 512;
 float max\_pixels\_tolerance = 2.0f;
 bool do\_image\_splitting = true;
 bool encoder\_act\_gelu = false;
 bool decoder\_act\_gelu = false;
 uint32\_t num\_encoder\_layers = 0;
 uint32\_t num\_decoder\_layers = 0;
 float partial\_rotary\_factor = 0.0f;
 uint32\_t pad\_token\_id = 0;
 uint32\_t conv\_kernel\_size = 0;
 uint32\_t subsampling\_conv\_kernel\_size = 0;
 uint32\_t subsampling\_conv\_stride = 0;
 uint32\_t subsampling\_conv\_channels = 0;
 uint32\_t subsampling\_factor = 0;
 uint32\_t num\_mel\_bins = 80;
 std::string encoder\_hidden\_act = "silu";
 uint32\_t linear\_num\_key\_heads = 0;
 uint32\_t linear\_key\_head\_dim = 0;
 uint32\_t linear\_num\_value\_heads = 0;
 uint32\_t linear\_value\_head\_dim = 0;
 uint32\_t linear\_q\_proj\_dim = 0;
 uint32\_t linear\_k\_proj\_dim = 0;
 uint32\_t linear\_v\_proj\_dim = 0;

 uint32\_t kv\_lora\_rank = 0;
 uint32\_t q\_lora\_rank = 0;
 uint32\_t qk\_head\_dim = 0;
 uint32\_t qk\_nope\_head\_dim = 0;
 uint32\_t qk\_rope\_head\_dim = 0;
 uint32\_t v\_head\_dim = 0;
 uint32\_t rope\_interleave = 0;
 bool attention\_bias = false;
 float rope\_scaling\_factor = 1.0f;
 float rope\_mscale\_all\_dim = 0.0f;

 enum class ModelType {QWEN = 0, GEMMA = 1, NOMIC = 3, LFM2 = 5, SIGLIP2 = 6, WHISPER = 7, MOONSHINE = 8, SILERO\_VAD = 9, PARAKEET = 10, QWEN3P5 = 11, PARAKEET\_TDT = 12, GEMMA3N = 13, YOUTU = 14, GEMMA4 = 15, PYANNOTE = 16, WESPEAKER = 17, NEEDLE = 18};
 uint32\_t predictor\_hidden\_dim = 0;
 uint32\_t predictor\_num\_layers = 0;
 uint32\_t tdt\_joint\_dim = 0;
 uint32\_t tdt\_num\_durations = 0;
 uint32\_t tdt\_blank\_id = 0;
 std::vector tdt\_durations;

 ModelType model\_type = ModelType::GEMMA4;

 enum class ModelVariant {DEFAULT = 0, VLM = 1, EXTRACT = 2, RAG = 3};
 ModelVariant model\_variant = ModelVariant::DEFAULT;

 enum class Activation {GELU = 0, SILU = 1};
 Activation activation = Activation::SILU;

 enum class Backend {CPU = 0, NPU = 1};
 Backend default\_backend = Backend::CPU;

 enum class Precision {INT8 = 0, FP16 = 1, FP32 = 2};
 Precision precision = Precision::FP32;

 float default\_temperature = 0.6f;
 float default\_top\_p = 0.95f;
 size\_t default\_top\_k = 20;
 float default\_max\_tps = -1.0f;
 float default\_cloud\_handoff\_threshold = 0.0f;
 size\_t default\_rolling\_entropy\_window = 10;

 std::vector layer\_types;
 size\_t conv\_L\_cache = 0;

 uint32\_t altup\_num\_inputs = 4;
 uint32\_t laurel\_rank = 64;
 static constexpr uint32\_t UNSET\_U32 = UINT32\_MAX;
 static constexpr float UNSET\_F32 = -1e30f;
 uint32\_t hidden\_size\_per\_layer\_input = UNSET\_U32;
 uint32\_t num\_kv\_shared\_layers = UNSET\_U32;
 uint32\_t sliding\_window = UNSET\_U32;
 float rope\_local\_base\_freq = UNSET\_F32;
 float final\_logit\_softcapping = UNSET\_F32;
 float global\_partial\_rotary\_factor = UNSET\_F32;
 uint32\_t expert\_intermediate\_size = 0;
 uint32\_t global\_head\_dim = UNSET\_U32;
 uint32\_t num\_global\_kv\_heads = 0;
 bool attention\_k\_eq\_v = false;
 bool enable\_moe\_block = false;
 std::vector activation\_sparsity\_ppf;

 uint32\_t vision\_head\_dim = 64;
 uint32\_t vision\_kv\_heads = 12;
 uint32\_t vision\_intermediate\_size = 3072;
 uint32\_t vision\_position\_embedding\_size = 10240;
 uint32\_t vision\_pooling\_kernel\_size = 3;
 uint32\_t vision\_default\_output\_length = 280;
 float vision\_rope\_theta = 100.0f;

 uint32\_t audio\_hidden\_dim = 0;
 uint32\_t audio\_num\_layers = 0;
 uint32\_t audio\_num\_heads = 0;
 uint32\_t audio\_head\_dim = 0;
 uint32\_t audio\_input\_feat\_size = 128;
 uint32\_t audio\_conf\_conv\_kernel\_size = 5;
 uint32\_t audio\_chunk\_size = 12;
 uint32\_t audio\_context\_left = 13;
 uint32\_t audio\_context\_right = 0;
 float audio\_logit\_cap = 50.0f;
 float audio\_residual\_weight = 0.5f;
 uint32\_t audio\_output\_proj\_dims = 0;
 uint32\_t audio\_vocab\_size = 128;
 uint32\_t audio\_vocab\_offset = 0;
 uint32\_t audio\_soft\_tokens = 188;
 uint32\_t audio\_sscp\_conv0\_channels = 128;
 uint32\_t audio\_sscp\_conv1\_channels = 32;
 float audio\_sscp\_conv\_eps = 1e-3f;
 float audio\_rms\_norm\_eps = 1e-6f;
 uint32\_t audio\_fft\_length = 1024;
 uint32\_t audio\_token\_id = 0;
 bool audio\_fft\_overdrive = false;
 uint32\_t channel\_open\_token\_id = 100;
 uint32\_t channel\_close\_token\_id = 101;

 static bool is\_gemma\_family(ModelType t) {
 return t == ModelType::GEMMA \|\| t == ModelType::GEMMA3N \|\| t == ModelType::GEMMA4;
 }

 bool from\_json(const std::string& json\_path);
 std::string to\_json() const;
};

struct MergeRule {
 std::string first;
 std::string second;
 std::string merged;
 uint32\_t priority;

 MergeRule(const std::string& f, const std::string& s, const std::string& m, uint32\_t p)
 : first(f), second(s), merged(m), priority(p) {}
};

struct ToolCallInfo {
 std::string name;
 std::string arguments;
};

struct ChatMessage {
 std::string role;
 std::string content;
 std::string name;
 std::vector images;
 std::vector audio;
 size\_t audio\_soft\_token\_count = 0;
 std::vector tool\_calls;
};

struct ToolConstraintSpec {
 std::string name;
 std::vector parameter\_names;
 std::vector required\_parameter\_names;
};

struct TokenizerRuntimeConfig {
 enum class TokenizerType { UNKNOWN, BPE, SENTENCEPIECE };
 enum class VocabFormat { UNKNOWN, ID\_TAB\_TOKEN, LINE\_TOKEN };
 enum class Normalizer { NONE, METASPACE, BYTE\_LEVEL };
 enum class Decoder { NONE, REPLACE\_METASPACE, BYTE\_LEVEL };

 TokenizerType tokenizer\_type = TokenizerType::UNKNOWN;
 VocabFormat vocab\_format = VocabFormat::UNKNOWN;
 Normalizer normalizer = Normalizer::NONE;
 Decoder decoder = Decoder::NONE;
 bool byte\_fallback = false;
 bool has\_chat\_template = false;
};

TokenizerRuntimeConfig load\_tokenizer\_runtime\_config(const std::string& config\_file);
void load\_special\_tokens\_map(const std::string& config\_file, std::unordered\_map& special\_tokens);
std::vector split\_with\_special\_tokens(const std::string& text, const std::unordered\_map& special\_tokens);

inline std::string extract\_json\_string(const std::string& json, size\_t& pos) {
 std::string value;
 while (pos < json.size() && json\[pos\] != '"') {
 if (json\[pos\] == '\\\' && pos + 1 < json.size()) {
 pos++;
 if (json\[pos\] == 'n') value += '\\n';
 else if (json\[pos\] == 't') value += '\\t';
 else if (json\[pos\] == 'r') value += '\\r';
 else if (json\[pos\] == '"') value += '"';
 else if (json\[pos\] == '\\\') value += '\\\';
 else value += json\[pos\];
 } else {
 value += json\[pos\];
 }
 pos++;
 }
 if (pos < json.size()) pos++;
 return value;
}

class Tokenizer {
public:
 virtual ~Tokenizer() = default;

 virtual std::vector encode(const std::string& text) const = 0;
 virtual std::string decode(const std::vector& tokens) const = 0;

 virtual std::vector apply\_chat\_template(const std::vector& messages, bool add\_generation\_prompt = true) const;
 virtual std::string format\_chat\_prompt(const std::vector& messages, bool add\_generation\_prompt = true, const std::string& tools\_json = "", bool enable\_thinking\_if\_supported = false) const;

 virtual uint32\_t get\_vocab\_size() const = 0;
 virtual uint32\_t get\_unk\_token() const = 0;
 virtual uint32\_t get\_bos\_token() const = 0;
 virtual uint32\_t get\_eos\_token() const = 0;
 virtual bool has\_chat\_template() const { return has\_chat\_template\_; }
 std::string get\_default\_stop\_sequence() const;

 virtual bool load\_vocabulary\_with\_config(const std::string& vocab\_file, const std::string& merges\_file, const std::string& config\_file) = 0;

 uint32\_t get\_image\_token\_id() const { return image\_token\_id\_; }
 uint32\_t get\_fake\_token\_id() const { return fake\_token\_id\_; }
 uint32\_t get\_global\_img\_token\_id() const { return global\_img\_token\_id\_; }

protected:
 enum class ModelType { UNKNOWN, GEMMA4, QWEN, LFM2 };
 ModelType model\_type\_ = ModelType::UNKNOWN;
 enum class ModelVariant { DEFAULT, VLM, EXTRACT, RAG};
 ModelVariant model\_variant\_ = ModelVariant::DEFAULT;
 bool has\_chat\_template\_ = false;
 std::string chat\_template\_;

 uint32\_t image\_token\_id\_ = 396;
 uint32\_t fake\_token\_id\_ = 49189;
 uint32\_t global\_img\_token\_id\_ = 49152;

 uint32\_t vision\_patch\_size\_ = 16;
 uint32\_t vision\_pooling\_kernel\_size\_ = 3;
 uint32\_t vision\_default\_output\_length\_ = 280;
 uint32\_t vision\_image\_size\_ = 768;
 TokenizerRuntimeConfig runtime\_config\_;

 void detect\_model\_type(const std::string& config\_path);
 void load\_chat\_template(const std::string& template\_file);
 std::string format\_gemma4\_style(const std::vector& messages, bool add\_generation\_prompt, const std::string& tools\_json, bool enable\_thinking\_if\_supported = false) const;
 std::string format\_qwen\_style(const std::vector& messages, bool add\_generation\_prompt, const std::string& tools\_json) const;
 std::string format\_lfm2\_style(const std::vector& messages, bool add\_generation\_prompt, const std::string& tools\_json) const;
};

class BPETokenizer : public Tokenizer {
public:
 BPETokenizer();
 ~BPETokenizer();

 bool load\_vocabulary\_mmap(const std::string& vocab\_file, const std::string& merges\_file);
 bool load\_vocabulary\_with\_config(const std::string& vocab\_file, const std::string& merges\_file, const std::string& config\_file) override;

 std::vector encode(const std::string& text) const override;
 std::string decode(const std::vector& tokens) const override;

 uint32\_t get\_vocab\_size() const override { return vocab\_size\_; }
 uint32\_t get\_unk\_token() const override { return unk\_token\_id\_; }
 uint32\_t get\_bos\_token() const override { return bos\_token\_id\_; }
 uint32\_t get\_eos\_token() const override { return eos\_token\_id\_; }

private:
 std::unordered\_map token\_to\_id\_;
 std::vector id\_to\_token\_;
 std::vector merge\_rules\_;
 std::unordered\_map merge\_map\_;

 uint32\_t vocab\_size\_;
 uint32\_t unk\_token\_id\_;
 uint32\_t bos\_token\_id\_;
 uint32\_t eos\_token\_id\_;

 void\* vocab\_mmap\_ptr\_;
 size\_t vocab\_mmap\_size\_;

 void\* merges\_mmap\_ptr\_;
 size\_t merges\_mmap\_size\_;

 std::vector apply\_bpe(const std::vector& tokens) const;
 std::pair find\_best\_merge\_fast(const std::vector& tokens) const;

 std::string bytes\_to\_unicode(const std::string& text) const;
 std::string unicode\_to\_bytes(const std::string& text) const;
 std::vector byte\_level\_split(const std::string& text) const;
 std::vector utf8\_split(const std::string& text) const;

 void cleanup\_mmap();

private:
 mutable std::unordered\_map byte\_to\_unicode\_;
 mutable std::unordered\_map unicode\_to\_byte\_;
 void init\_byte\_mappings() const;

 std::unordered\_map special\_tokens\_;
 std::vector split\_with\_special\_tokens(const std::string& text) const;
 void load\_special\_tokens(const std::string& config\_file);
};

class SPTokenizer : public Tokenizer {
public:
 SPTokenizer();
 ~SPTokenizer();

 bool load\_vocabulary\_with\_config(const std::string& vocab\_file, const std::string& merges\_file, const std::string& config\_file) override;

 std::vector encode(const std::string& text) const override;
 std::string decode(const std::vector& tokens) const override;

 uint32\_t get\_vocab\_size() const override { return vocab\_size\_; }
 uint32\_t get\_unk\_token() const override { return unk\_token\_id\_; }
 uint32\_t get\_bos\_token() const override { return bos\_token\_id\_; }
 uint32\_t get\_eos\_token() const override { return eos\_token\_id\_; }

private:
 struct TrieNode {
 std::unordered\_map\> children;
 int32\_t token\_id = -1;
 float score = 0.0f;
 };

 std::unique\_ptr trie\_root\_;
 std::unordered\_map token\_to\_id\_;
 std::vector id\_to\_token\_;
 std::vector token\_scores\_;

 uint32\_t vocab\_size\_;
 uint32\_t unk\_token\_id\_;
 uint32\_t bos\_token\_id\_;
 uint32\_t eos\_token\_id\_;
 uint32\_t pad\_token\_id\_;

 bool sp\_bpe\_mode\_ = false;
 bool sp\_add\_dummy\_prefix\_ = false;
 bool sp\_byte\_fallback\_ = false;

 void\* vocab\_mmap\_ptr\_;
 size\_t vocab\_mmap\_size\_;

 void build\_trie();
 std::vector\> tokenize\_with\_trie(const std::string& text) const;
 std::vector tokenize\_with\_bpe(const std::string& text) const;
 std::string preprocess\_text(const std::string& text) const;
 std::string postprocess\_text(const std::string& text) const;
 std::vector split\_by\_unicode\_spaces(const std::string& text) const;

 void cleanup\_mmap();

 std::unordered\_map special\_tokens\_;
 std::vector split\_with\_special\_tokens(const std::string& text) const;
 void load\_special\_tokens(const std::string& config\_file);
};

class ToolCallConstrainer {
public:
 enum class State {
 DONE,
 GEMMA\_START,
 GEMMA\_EXPECT\_CALL,
 GEMMA\_IN\_FUNC\_NAME,
 GEMMA\_EXPECT\_BRACE,
 GEMMA\_IN\_ARGUMENTS,
 GEMMA\_EXPECT\_END
 };

 void init(Config::ModelType model\_type,
 const std::vector& tools,
 Tokenizer\* tokenizer);

 const std::unordered\_map& get\_bias() const { return current\_bias\_; }

 void update(uint32\_t token\_id, const std::string& decoded\_text);

 void reset();

 bool is\_active() const { return active\_; }

private:
 bool active\_ = false;
 State state\_ = State::GEMMA\_START;
 Config::ModelType model\_type\_ = Config::ModelType::GEMMA4;
 Tokenizer\* tokenizer\_ = nullptr;

 std::vector tool\_specs\_;
 std::vector function\_names\_;
 std::string generated\_text\_;
 int brace\_depth\_ = 0;
 bool in\_argument\_string\_ = false;

 std::string call\_start\_tag\_;
 std::string call\_end\_tag\_;

 std::unordered\_set all\_func\_name\_tokens\_;
 std::unordered\_map\> func\_name\_sequences\_;

 std::unordered\_set gemma\_call\_start\_tokens\_;
 std::unordered\_set gemma\_call\_end\_tokens\_;
 std::unordered\_set gemma\_response\_start\_tokens\_;
 std::unordered\_set gemma\_call\_prefix\_tokens\_;
 std::unordered\_set escape\_tokens\_;

 std::unordered\_set backtick\_tokens\_;
 std::unordered\_set open\_brace\_tokens\_;
 std::unordered\_set close\_brace\_tokens\_;
 std::unordered\_set colon\_tokens\_;
 std::unordered\_set comma\_tokens\_;

 std::unordered\_map current\_bias\_;

 void compute\_bias();
 void tokenize\_grammar\_elements();
 void add\_tokens\_for\_string(const std::string& str, std::unordered\_set& token\_set);
 void add\_tokens\_for\_prefix\_string(const std::string& prefix, std::unordered\_set& token\_set);
 void tokenize\_function\_names(bool quote\_names);
 void init\_common\_tokens();
};

class Model {
public:
 struct DebugNode {
 uint32\_t layer\_idx;
 std::string name;
 size\_t node\_id;
 };

 Model();
 explicit Model(const Config& config);
 virtual ~Model();

 const Config& get\_config() const { return config\_; }
 Tokenizer\* get\_tokenizer() const { return tokenizer\_.get(); }
 const std::vector& get\_debug\_nodes() const;

 virtual bool init(const std::string& model\_folder, size\_t context\_size, const std::string& system\_prompt = "", bool do\_warmup = true);

 virtual bool init(CactusGraph\* external\_graph, const std::string& model\_folder, size\_t context\_size,
 const std::string& system\_prompt = "", bool do\_warmup = true);

 virtual uint32\_t decode(const std::vector& tokens, float temperature = -1.0f, float top\_p = -1.0f,
 size\_t top\_k = 0, const std::string& profile\_file = "", float\* out\_entropy = nullptr,
 float min\_p = 0.15f, float repetition\_penalty = 1.1f);

 virtual void prefill(const std::vector& tokens, size\_t chunk\_size = 256, const std::string& profile\_file = "");

 virtual void prefill\_with\_images(const std::vector& tokens, const std::vector& image\_paths,
 const std::string& profile\_file = "");

 virtual uint32\_t decode\_with\_images(const std::vector& tokens, const std::vector& image\_paths,
 float temperature = -1.0f, float top\_p = -1.0f,
 size\_t top\_k = 0, const std::string& profile\_file = "", float\* out\_entropy = nullptr,
 float min\_p = 0.15f, float repetition\_penalty = 1.1f);

 virtual uint32\_t decode\_with\_audio(const std::vector& tokens, const std::vector& audio\_features, float temperature = 0.0f, float top\_p = 0.0f,
 size\_t top\_k = 0, const std::string& profile\_file = "", float\* out\_entropy = nullptr,
 float min\_p = 0.15f, float repetition\_penalty = 1.1f,
 float\* out\_token\_time\_start = nullptr, float\* out\_token\_time\_end = nullptr);

 std::vector get\_embeddings(const std::vector& tokens, bool pooled = true, bool normalize = false, const std::string& profile\_file = "");

 virtual std::vector get\_image\_embeddings(const std::string& image\_path);

 virtual std::vector get\_audio\_embeddings(const std::vector& audio\_features);

 virtual void reset\_cache();
 void record\_sampled\_token(uint32\_t token) {
 if (token\_history\_.size() >= MAX\_TOKEN\_HISTORY) {
 token\_history\_.erase(token\_history\_.begin(), token\_history\_.begin() + (MAX\_TOKEN\_HISTORY / 2));
 }
 token\_history\_.push\_back(token);
 }

 double score\_tokens\_window\_logprob(const std::vector& tokens, size\_t start, size\_t end, size\_t context, size\_t\* tokens\_scored);

 void set\_cache\_window(size\_t window\_size, size\_t sink\_size = 4);
 size\_t get\_cache\_size() const;

 bool load\_npu\_prefill(const std::string& model\_path);
 bool has\_npu\_prefill() const;
 size\_t get\_prefill\_chunk\_size() const;

 virtual void remove\_thinking\_tokens(const std::vector>& ranges);
 virtual void compact\_kv\_cache() {}

 virtual void set\_tool\_constraints(const std::vector& tools);
 virtual void clear\_tool\_constraints();
 virtual void update\_tool\_constraints(uint32\_t token\_id);

 void\* graph\_handle\_;

 void set\_vocab\_bias(const std::unordered\_map& bias) {
 vocab\_bias\_ = bias;
 }

 void clear\_vocab\_bias() {
 vocab\_bias\_.clear();
 }

 bool has\_vocab\_bias() const {
 return !vocab\_bias\_.empty();
 }

 const std::unordered\_map& get\_vocab\_bias() const {
 return vocab\_bias\_;
 }

protected:
 size\_t sample\_token(CactusGraph\* gb, size\_t logits\_node\_id, float temperature, float top\_p, size\_t top\_k,
 float min\_p, float repetition\_penalty,
 const std::unordered\_map\\* extra\_bias = nullptr) const;

 static void compute\_entropy(CactusGraph\* gb, size\_t logits\_node\_id, float\* out\_entropy);

 virtual size\_t forward(const std::vector& tokens, bool use\_cache = false) = 0;

 virtual size\_t forward(const std::vector& audio\_features, const std::vector& tokens, bool use\_cache = false);

 virtual void load\_weights\_to\_graph(CactusGraph\* gb) = 0;

 virtual size\_t build\_attention(CactusGraph\* gb, size\_t normalized\_input, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) = 0;

 virtual size\_t build\_mlp(CactusGraph\* gb, size\_t normalized\_h, uint32\_t layer\_idx,
 ComputeBackend backend) const = 0;
 virtual size\_t build\_transformer\_block(CactusGraph\* gb, size\_t hidden, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) = 0;
 virtual std::vector get\_kv\_layer\_dims() const {
 return std::vector(config\_.num\_layers, config\_.attention\_head\_dim);
 }
 virtual std::vector get\_kv\_layer\_heads() const {
 return std::vector(config\_.num\_layers, config\_.attention\_kv\_heads);
 }
 virtual std::vector get\_kv\_layer\_windows() const {
 return std::vector(config\_.num\_layers, 0);
 }
 virtual void post\_init() {}
 virtual void post\_execute\_updates(CactusGraph\*, size\_t) {}
 Config config\_;
 std::unique\_ptr tokenizer\_;

 bool initialized\_;
 float attention\_scale\_;

protected:
 std::vector graph\_cache\_k\_nodes\_;
 std::vector graph\_cache\_v\_nodes\_;
 size\_t cache\_total\_seq\_len\_ = 0;
 size\_t cache\_window\_size\_ = 0;
 size\_t cache\_sink\_size\_ = 4;
 size\_t cache\_max\_seq\_len\_ = 2048;
 void init\_graph\_cache(CactusGraph\* gb);
 void invalidate\_graph\_cache(CactusGraph\* gb);

 std::string embedding\_file\_path\_;
 size\_t embedding\_node\_id\_;
 std::string model\_folder\_path\_;
 size\_t output\_weight\_node\_id\_;

 mutable std::vector debug\_nodes\_;

 void capture\_debug\_node(uint32\_t layer\_idx, const std::string& name, size\_t node\_id) const;
 void clear\_debug\_nodes();

 bool init\_internal(CactusGraph\* gb, const std::string& model\_folder, size\_t context\_size,
 const std::string& system\_prompt, bool do\_warmup);
 bool owns\_graph\_;

 std::unique\_ptr npu\_prefill\_;
 void prefill\_npu(const std::vector& tokens);
 virtual std::vector<\_\_fp16> get\_token\_embeddings(const std::vector& tokens);

 static constexpr size\_t MAX\_TOKEN\_HISTORY = 128;
 ToolCallConstrainer tool\_constrainer\_;
 std::vector token\_history\_;

private:
 std::unordered\_map vocab\_bias\_;
};

class ConvCache {
public:
 struct CircularView {
 const void\* ptr1;
 size\_t len1;
 const void\* ptr2;
 size\_t len2;
 size\_t total\_len;
 };

 void init(size\_t layers, size\_t hidden\_dim, size\_t window\_len, Precision model\_precision);
 CircularView get\_window(size\_t layer) const;
 void update(CactusGraph\* gb, size\_t layer, const size\_t latest\_token);
 void reset();

 bool is\_empty() const { return num\_layers == 0; }

 size\_t num\_layers = 0;
 size\_t hidden\_size = 0;
 size\_t window\_size = 0;
 Precision precision = Precision::FP32;
 size\_t element\_size = 4;

private:
 struct LayerState {
 std::vector data;
 size\_t head = 0;
 size\_t count = 0;
 };

 std::vector layer\_states;
};

class Siglip2Preprocessor {
public:
 struct Config {
 int patch\_size = 16;
 int downsample\_factor = 2;
 int min\_tiles = 2;
 int max\_tiles = 10;
 bool use\_thumbnail = true;
 int min\_image\_tokens = 64;
 int max\_image\_tokens = 256;
 int max\_num\_patches = 1024;
 int tile\_size = 512;
 float max\_pixels\_tolerance = 2.0f;
 bool do\_resize = true;
 bool do\_rescale = true;
 bool do\_normalize = true;
 bool do\_convert\_rgb = true;
 bool do\_image\_splitting = true;
 float rescale\_factor = 1.0f / 255.0f;
 float image\_mean\[3\] = {0.5f, 0.5f, 0.5f};
 float image\_std\[3\] = {0.5f, 0.5f, 0.5f};
 };

 struct PreprocessedImage {
 std::vector pixel\_values;
 std::vector pixel\_attention\_mask;
 std::vector\> spatial\_shapes;
 std::vector pixel\_values\_shape;
 std::vector pixel\_attention\_mask\_shape;
 std::vector spatial\_shapes\_shape;
 int num\_patches\_height;
 int num\_patches\_width;
 int actual\_num\_patches;
 int num\_tiles;
 int patch\_dim;
 int max\_patches\_per\_tile;
 int image\_rows;
 int image\_cols;
 int image\_height;
 int image\_width;
 int tokens\_per\_tile;
 int thumbnail\_tokens;

 ~PreprocessedImage();
 };

 struct SpatialShapeResult {
 std::vector\> shapes;
 int grid\_rows;
 int grid\_cols;
 };

 explicit Siglip2Preprocessor(const Config& config);
 Siglip2Preprocessor();
 ~Siglip2Preprocessor();

 PreprocessedImage preprocess\_from\_file(const std::string& image\_path);
 PreprocessedImage preprocess\_from\_memory(const unsigned char\* img\_data, int width, int height, int channels);
 SpatialShapeResult compute\_spatial\_shapes(int height, int width);

private:
 Config config\_;

 std::pair compute\_pixel\_limits() const;
 std::vector convert\_to\_rgb(const unsigned char\* img\_data, int width, int height, int channels);
 std::pair smart\_resize(int height, int width);
 bool is\_image\_too\_large(int height, int width);
 std::pair get\_grid\_layout(int height, int width);
 std::pair find\_closest\_aspect\_ratio(float aspect\_ratio, int width, int height);
 std::vector resize\_image(const unsigned char\* img\_data, int src\_width, int src\_height,
 int dst\_width, int dst\_height, int channels);
 std::vector normalize\_image(const float\* img\_data, int width, int height, int channels);
 std::vector\> convert\_image\_to\_patches(
 const std::vector& image, int width, int height, int channels, int patch\_size);
 PreprocessedImage pad\_patches(const std::vector>& tile\_patches,
 const std::vector>& spatial\_shapes,
 int patch\_dim,
 int max\_patches\_per\_tile);
 int round\_by\_factor(int number, int factor);
};

std::unique\_ptr create\_model(const std::string& model\_folder);

struct SpectrogramConfig {
 size\_t n\_fft = 400;
 size\_t hop\_length = 160;
 size\_t frame\_length = 400;
 float power = 2.0f;
 bool center = true;
 const char\* pad\_mode = "reflect";
 bool onesided = true;
 float dither = 0.0f;
 float mel\_floor = 1e-10f;
 const char\* log\_mel = nullptr;
 float reference = 1.0f;
 float min\_value = 1e-10f;
 bool remove\_dc\_offset = false;
 float preemphasis = 0.0f;
 bool hann\_periodic = true;
 float window\_a0 = 0.5f;
 size\_t fft\_override = 0;
 bool mel\_floor\_additive = false;
};

namespace index {
 constexpr uint32\_t MAGIC = 0x43414354;
 constexpr uint32\_t VERSION = 1;

 struct Document {
 int id;
 std::vector embedding;
 std::string content;
 std::string metadata;
 };

 struct QueryResult {
 int doc\_id;
 float score;

 QueryResult(int doc\_id, float score) : doc\_id(doc\_id), score(score) {}
 };

 struct QueryOptions {
 size\_t top\_k = 10;
 float score\_threshold = -1.0f;
 };

 class Index {
 public:
 Index(const std::string& index\_path, const std::string& data\_path, size\_t embedding\_dim);
 ~Index();

 Index(const Index&) = delete;
 Index& operator=(const Index&) = delete;
 Index(Index&&) = delete;
 Index& operator=(Index&&) = delete;

 void add\_documents(const std::vector& documents);
 void delete\_documents(const std::vector& doc\_ids);
 std::vector get\_documents(const std::vector& doc\_ids);
 std::vector\> query(const std::vector>& embeddings, const QueryOptions& options);
 void compact();

 private:
 struct IndexHeader {
 uint32\_t magic;
 uint32\_t version;
 uint32\_t embedding\_dim;
 uint32\_t num\_documents;
 };

 struct IndexEntry {
 int32\_t doc\_id;
 uint64\_t data\_offset;
 uint8\_t flags; // bit 0: tombstone

 const \_\_fp16\* embedding() const {
 return reinterpret\_cast(this + 1);
 }

 static size\_t size(size\_t embedding\_dim) {
 return sizeof(IndexEntry) + embedding\_dim \* sizeof(\_\_fp16);
 }
 };

 struct DataHeader {
 uint32\_t magic;
 uint32\_t version;
 };

 struct DataEntry {
 uint16\_t content\_len;
 uint16\_t metadata\_len;

 const char\* content() const {
 return reinterpret\_cast(this + 1);
 }

 const char\* metadata() const {
 return content() + content\_len;
 }
 };

 void parse\_index\_header();
 void parse\_data\_header();
 void build\_doc\_id\_map();
 void validate\_documents(const std::vector& documents);
 void validate\_doc\_ids(const std::vector& doc\_ids);
 ssize\_t write\_full(int fd, const void\* buf, size\_t count);

 std::unordered\_map doc\_id\_map\_;

 std::string index\_path\_, data\_path\_;
 size\_t embedding\_dim\_;
 size\_t index\_entry\_size\_;
 uint32\_t num\_documents\_;

 int index\_fd\_, data\_fd\_;
 void \*mapped\_index\_, \*mapped\_data\_;
 size\_t index\_file\_size\_, data\_file\_size\_;
 };
} // namespace index

}
}