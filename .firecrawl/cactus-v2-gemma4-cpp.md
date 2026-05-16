#include "model\_gemma4.h"
#include "cactus\_graph.h"
#include
#include
#include
#include

namespace cactus {
namespace engine {

Gemma4Model::Gemma4Model() : Model() {}

Gemma4Model::Gemma4Model(const Config& config) : Model(config) {
 weight\_nodes\_.layers.resize(config.num\_layers);
}

bool Gemma4Model::is\_global\_layer(uint32\_t idx) const {
 return idx < config\_.layer\_types.size() &&
 (config\_.layer\_types\[idx\] == "global" \|\| config\_.layer\_types\[idx\] == "full\_attention");
}

std::vector Gemma4Model::get\_kv\_layer\_dims() const {
 uint32\_t n = config\_.num\_layers;

 std::vector dims(n);
 for (uint32\_t i = 0; i < n; i++) {
 if (i >= first\_shared\_layer\_) {
 dims\[i\] = 0;
 } else if (is\_global\_layer(i)) {
 dims\[i\] = config\_.global\_head\_dim > 0 ? config\_.global\_head\_dim : config\_.attention\_head\_dim \* 2;
 } else {
 dims\[i\] = config\_.attention\_head\_dim;
 }
 }
 return dims;
}

std::vector Gemma4Model::get\_kv\_layer\_heads() const {
 uint32\_t n = config\_.num\_layers;

 std::vector heads(n);
 for (uint32\_t i = 0; i < n; i++) {
 if (i >= first\_shared\_layer\_) {
 heads\[i\] = 0;
 } else if (is\_global\_layer(i) && config\_.num\_global\_kv\_heads > 0) {
 heads\[i\] = config\_.num\_global\_kv\_heads;
 } else {
 heads\[i\] = config\_.attention\_kv\_heads;
 }
 }
 return heads;
}

std::vector Gemma4Model::get\_kv\_layer\_windows() const {
 uint32\_t n = config\_.num\_layers;
 std::vector windows(n, 0);
 for (uint32\_t i = 0; i < n; i++) {
 if (i >= first\_shared\_layer\_) {
 windows\[i\] = 0; // shared layers don't have own cache
 } else if (!is\_global\_layer(i)) {
 windows\[i\] = config\_.sliding\_window; // local layers use sliding window
 }
 }
 return windows;
}

void Gemma4Model::compact\_kv\_cache() {
}

void Gemma4Model::post\_init() {
 uint32\_t n = config\_.num\_layers;

 cache\_window\_size\_ = 0; // disable uniform window; per-layer windows via get\_kv\_layer\_windows()

 auto\* gb = static\_cast(graph\_handle\_);
 init\_graph\_cache(gb);

 kv\_share\_map\_.resize(n, -1);
 shared\_k\_nodes\_.resize(n, 0);
 shared\_v\_nodes\_.resize(n, 0);

 for (uint32\_t i = first\_shared\_layer\_; i < n; i++) {
 bool is\_global = is\_global\_layer(i);
 for (int j = static\_cast(first\_shared\_layer\_) - 1; j >= 0; j--) {
 if (is\_global\_layer(j) == is\_global) {
 kv\_share\_map\_\[i\] = j;
 break;
 }
 }
 }
}

void Gemma4Model::load\_weights\_to\_graph(CactusGraph\* gb) {
 uint32\_t n = config\_.num\_layers;
 uint32\_t num\_shared = config\_.num\_kv\_shared\_layers;
 first\_shared\_layer\_ = (n > num\_shared) ? n - num\_shared : n;

 embedding\_node\_id\_ = gb->mmap\_embeddings(embedding\_file\_path\_);
 weight\_nodes\_.output\_norm\_weight = gb->mmap\_weights(model\_folder\_path\_ + "/output\_norm.weights");
 if (config\_.tie\_word\_embeddings) {
 weight\_nodes\_.output\_weight = embedding\_node\_id\_;
 output\_weight\_node\_id\_ = embedding\_node\_id\_;
 } else {
 weight\_nodes\_.output\_weight = gb->mmap\_weights(model\_folder\_path\_ + "/output\_weight.weights");
 output\_weight\_node\_id\_ = weight\_nodes\_.output\_weight;
 }

 bool has\_pli = config\_.hidden\_size\_per\_layer\_input > 0;
 if (has\_pli) {
 weight\_nodes\_.embed\_tokens\_per\_layer = gb->mmap\_embeddings(model\_folder\_path\_ + "/embed\_tokens\_per\_layer.weights");
 weight\_nodes\_.per\_layer\_model\_proj = gb->mmap\_weights(model\_folder\_path\_ + "/per\_layer\_model\_proj.weights");
 weight\_nodes\_.per\_layer\_proj\_norm = gb->mmap\_weights(model\_folder\_path\_ + "/per\_layer\_proj\_norm.weights");
 }

 bool has\_moe = config\_.enable\_moe\_block;

 for (uint32\_t i = 0; i < config\_.num\_layers; i++) {
 auto& layer = weight\_nodes\_.layers\[i\];
 std::string prefix = model\_folder\_path\_ + "/layer\_" + std::to\_string(i) + "\_";
 bool is\_shared = (i >= first\_shared\_layer\_);

 layer.attn\_q\_weight = gb->mmap\_weights(prefix + "attn\_q.weights");
 layer.attn\_k\_weight = is\_shared ? 0 : gb->mmap\_weights(prefix + "attn\_k.weights");
 bool k\_eq\_v = config\_.attention\_k\_eq\_v && is\_global\_layer(i);
 layer.attn\_v\_weight = is\_shared ? 0 : (k\_eq\_v ? layer.attn\_k\_weight : gb->mmap\_weights(prefix + "attn\_v.weights"));
 layer.attn\_output\_weight = gb->mmap\_weights(prefix + "attn\_output.weights");
 layer.input\_layernorm\_weight = gb->mmap\_weights(prefix + "input\_norm.weights");
 layer.attn\_q\_norm\_weight = gb->mmap\_weights(prefix + "attn\_q\_norm.weights");
 layer.attn\_k\_norm\_weight = is\_shared ? 0 : gb->mmap\_weights(prefix + "attn\_k\_norm.weights");
 layer.ffn\_gate\_weight = gb->mmap\_weights(prefix + "ffn\_gate.weights");
 layer.ffn\_up\_weight = gb->mmap\_weights(prefix + "ffn\_up.weights");
 layer.ffn\_down\_weight = gb->mmap\_weights(prefix + "ffn\_down.weights");
 layer.post\_attention\_layernorm\_weight = gb->mmap\_weights(prefix + "post\_attn\_norm.weights");
 layer.pre\_feedforward\_layernorm\_weight = gb->mmap\_weights(prefix + "pre\_ffn\_norm.weights");
 layer.post\_feedforward\_layernorm\_weight = gb->mmap\_weights(prefix + "post\_ffn\_norm.weights");
 if (has\_pli) {
 layer.per\_layer\_gate = gb->mmap\_weights(prefix + "per\_layer\_gate.weights");
 layer.per\_layer\_proj = gb->mmap\_weights(prefix + "per\_layer\_proj.weights");
 layer.post\_per\_layer\_norm = gb->mmap\_weights(prefix + "post\_per\_layer\_norm.weights");
 }
 layer.layer\_scalar = std::filesystem::exists(prefix + "layer\_scalar.weights") ? gb->mmap\_weights(prefix + "layer\_scalar.weights") : 0;

 if (has\_moe) {
 uint32\_t num\_experts = config\_.num\_experts;
 uint32\_t hidden = config\_.hidden\_dim;
 uint32\_t expert\_dim = config\_.expert\_intermediate\_size > 0 ? config\_.expert\_intermediate\_size : config\_.ffn\_intermediate\_dim;
 layer.moe\_w1\_experts.resize(num\_experts);
 layer.moe\_w3\_experts.resize(num\_experts);
 layer.moe\_w2\_experts.resize(num\_experts);

 auto w1\_packed = gb->mmap\_weights(prefix + "moe\_gate\_proj.weights");
 auto w3\_packed = gb->mmap\_weights(prefix + "moe\_up\_proj.weights");
 auto w2\_packed = gb->mmap\_weights(prefix + "moe\_down\_proj.weights");

 const auto& w1\_buf = gb->get\_output\_buffer(w1\_packed);
 const auto& w3\_buf = gb->get\_output\_buffer(w3\_packed);
 const auto& w2\_buf = gb->get\_output\_buffer(w2\_packed);

 auto setup\_experts = \[&\](const BufferDesc& buf,
 std::vector& expert\_nodes,
 size\_t out\_dim, size\_t in\_dim) {
 auto\* base = static\_cast(const\_cast(buf.get\_data()));
 Precision prec = buf.precision;
 size\_t K = in\_dim;
 size\_t expert\_data\_bytes = PrecisionTraits::packed\_size\_of(prec, out\_dim \* K);

 for (uint32\_t e = 0; e < num\_experts; e++) {
 expert\_nodes\[e\] = gb->input({out\_dim, K}, prec);
 gb->set\_external\_input(expert\_nodes\[e\], base + e \* expert\_data\_bytes, prec);
 }
 };

 setup\_experts(w1\_buf, layer.moe\_w1\_experts, expert\_dim, hidden);
 setup\_experts(w3\_buf, layer.moe\_w3\_experts, expert\_dim, hidden);
 setup\_experts(w2\_buf, layer.moe\_w2\_experts, hidden, expert\_dim);

 layer.router\_proj = gb->mmap\_weights(prefix + "router\_proj.weights");
 layer.router\_scale = gb->mmap\_weights(prefix + "router\_scale.weights");
 layer.moe\_per\_expert\_scale = gb->mmap\_weights(prefix + "moe\_per\_expert\_scale.weights");
 layer.post\_ffn\_norm\_1 = gb->mmap\_weights(prefix + "post\_ffn\_norm\_1.weights");
 layer.pre\_ffn\_norm\_2 = gb->mmap\_weights(prefix + "pre\_ffn\_norm\_2.weights");
 layer.post\_ffn\_norm\_2 = gb->mmap\_weights(prefix + "post\_ffn\_norm\_2.weights");
 }
 }

 size\_t sliding\_head\_dim = config\_.attention\_head\_dim;
 size\_t global\_head\_dim = config\_.global\_head\_dim > 0 ? config\_.global\_head\_dim : config\_.attention\_head\_dim \* 2;
 v\_norm\_ones\_weight\_.assign(std::max(sliding\_head\_dim, global\_head\_dim), static\_cast<\_\_fp16>(1.0f));
 v\_norm\_ones\_node\_ = gb->input({sliding\_head\_dim}, Precision::FP16);
 gb->set\_external\_input(v\_norm\_ones\_node\_, v\_norm\_ones\_weight\_.data(), Precision::FP16);
 v\_norm\_ones\_global\_node\_ = gb->input({global\_head\_dim}, Precision::FP16);
 gb->set\_external\_input(v\_norm\_ones\_global\_node\_, v\_norm\_ones\_weight\_.data(), Precision::FP16);

 if (npu::is\_npu\_available()) {
 std::string npu\_prefill\_path = model\_folder\_path\_ + "/model.mlpackage";
 if (std::filesystem::exists(npu\_prefill\_path)) {
 if (!load\_npu\_prefill(npu\_prefill\_path) \|\| !has\_npu\_prefill()) {
 CACTUS\_LOG\_DEBUG("npu", "\[gemma4\] found model.mlpackage but failed to enable NPU prefill; using CPU prefill");
 }
 }
 }
}

size\_t Gemma4Model::build\_per\_layer\_input(CactusGraph\* gb, size\_t hidden, size\_t pli\_combined, uint32\_t layer\_idx,
 ComputeBackend backend) const {
 const auto& layer = weight\_nodes\_.layers\[layer\_idx\];
 uint32\_t pli\_dim = config\_.hidden\_size\_per\_layer\_input;

 auto gate = gb->gelu(gb->matmul(hidden, layer.per\_layer\_gate, true, backend));
 auto pli\_slice = gb->slice(pli\_combined, 1, layer\_idx \* pli\_dim, pli\_dim);
 auto gated = gb->multiply(gate, pli\_slice);
 auto pli\_proj = gb->matmul(gated, layer.per\_layer\_proj, true, backend);
 auto pli\_normed = gb->rms\_norm(pli\_proj, layer.post\_per\_layer\_norm, config\_.layer\_norm\_eps);

 return gb->add(hidden, pli\_normed);
}

size\_t Gemma4Model::apply\_partial\_rope(CactusGraph\* gb, size\_t tensor, size\_t head\_dim, size\_t rot\_dim,
 float rope\_freq, size\_t position\_offset) {
 if (rot\_dim < head\_dim) {
 size\_t half\_dim = head\_dim / 2;
 size\_t half\_rot = rot\_dim / 2;
 size\_t pass\_len = half\_dim - half\_rot;
 float adjusted\_theta = std::pow(rope\_freq, static\_cast(rot\_dim) / static\_cast(head\_dim));

 auto left\_rot = gb->slice(tensor, 3, 0, half\_rot);
 auto left\_pass = gb->slice(tensor, 3, half\_rot, pass\_len);
 auto right\_rot = gb->slice(tensor, 3, half\_dim, half\_rot);
 auto right\_pass = gb->slice(tensor, 3, half\_dim + half\_rot, pass\_len);

 auto rotated = gb->rope(gb->concat(left\_rot, right\_rot, 3), adjusted\_theta, position\_offset);
 auto rotated\_left = gb->slice(rotated, 3, 0, half\_rot);
 auto rotated\_right = gb->slice(rotated, 3, half\_rot, half\_rot);

 auto new\_left = gb->concat(rotated\_left, left\_pass, 3);
 auto new\_right = gb->concat(rotated\_right, right\_pass, 3);
 return gb->concat(new\_left, new\_right, 3);
 }
 return gb->rope(tensor, rope\_freq, position\_offset);
}

size\_t Gemma4Model::build\_attention(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache, size\_t position\_offset) {
 const auto& layer = weight\_nodes\_.layers\[layer\_idx\];
 size\_t seq\_len = gb->get\_output\_buffer(input).shape\[0\];
 int share\_src = (layer\_idx < kv\_share\_map\_.size()) ? kv\_share\_map\_\[layer\_idx\] : -1;

 bool is\_global = is\_global\_layer(layer\_idx);

 size\_t head\_dim = is\_global ? (config\_.global\_head\_dim > 0 ? config\_.global\_head\_dim : config\_.attention\_head\_dim \* 2) : config\_.attention\_head\_dim;
 size\_t num\_heads = config\_.attention\_heads;
 size\_t kv\_heads = is\_global && config\_.num\_global\_kv\_heads > 0 ? config\_.num\_global\_kv\_heads : config\_.attention\_kv\_heads;
 float rope\_freq = is\_global ? config\_.rope\_theta : config\_.rope\_local\_base\_freq;
 size\_t window = is\_global ? 0 : config\_.sliding\_window;
 size\_t rot\_dim = static\_cast(head\_dim \* (is\_global ? config\_.global\_partial\_rotary\_factor : 1.0f));

 auto q = gb->matmul(input, layer.attn\_q\_weight, true, backend);
 q = gb->reshape(q, {seq\_len \* num\_heads, head\_dim});
 q = gb->rms\_norm(q, layer.attn\_q\_norm\_weight, config\_.layer\_norm\_eps);
 q = gb->reshape(q, {1, seq\_len, num\_heads, head\_dim});

 size\_t q4 = apply\_partial\_rope(gb, q, head\_dim, rot\_dim, rope\_freq, position\_offset);

 size\_t k4, v4;
 if (share\_src >= 0 && shared\_k\_nodes\_\[share\_src\] != 0) {
 k4 = shared\_k\_nodes\_\[share\_src\];
 v4 = shared\_v\_nodes\_\[share\_src\];
 } else {
 auto k = gb->matmul(input, layer.attn\_k\_weight, true, backend);
 k = gb->reshape(k, {seq\_len \* kv\_heads, head\_dim});
 k = gb->rms\_norm(k, layer.attn\_k\_norm\_weight, config\_.layer\_norm\_eps);
 k = gb->reshape(k, {1, seq\_len, kv\_heads, head\_dim});

 k4 = apply\_partial\_rope(gb, k, head\_dim, rot\_dim, rope\_freq, position\_offset);

 auto v\_proj = gb->matmul(input, layer.attn\_v\_weight, true, backend);
 size\_t v\_ones = is\_global ? v\_norm\_ones\_global\_node\_ : v\_norm\_ones\_node\_;
 auto v = gb->rms\_norm(gb->reshape(v\_proj, {seq\_len \* kv\_heads, head\_dim}), v\_ones, config\_.layer\_norm\_eps);
 v4 = gb->reshape(v, {1, seq\_len, kv\_heads, head\_dim});

 shared\_k\_nodes\_\[layer\_idx\] = k4;
 shared\_v\_nodes\_\[layer\_idx\] = v4;
 }

 size\_t cache\_src = (share\_src >= 0) ? static\_cast(share\_src) : layer\_idx;
 size\_t attn;
 if (use\_cache && graph\_cache\_k\_nodes\_\[cache\_src\] != 0) {
 if (share\_src < 0) {
 gb->kv\_cache\_append(k4, graph\_cache\_k\_nodes\_\[cache\_src\], window, cache\_sink\_size\_);
 gb->kv\_cache\_append(v4, graph\_cache\_v\_nodes\_\[cache\_src\], window, cache\_sink\_size\_);
 }
 attn = gb->attention\_cached(q4, k4, v4,
 graph\_cache\_k\_nodes\_\[cache\_src\], graph\_cache\_v\_nodes\_\[cache\_src\],
 attention\_scale\_, position\_offset, window);
 } else {
 attn = gb->attention(q4, k4, v4, attention\_scale\_, position\_offset, window);
 }

 return gb->matmul(gb->reshape(attn, {seq\_len, num\_heads \* head\_dim}), layer.attn\_output\_weight, true, backend);
}

size\_t Gemma4Model::build\_mlp(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx,
 ComputeBackend backend) const {
 const auto& layer = weight\_nodes\_.layers\[layer\_idx\];
 static const bool dense\_mlp\_fused\_disabled = \[\]() {
 const char\* env = std::getenv("CACTUS\_DISABLE\_DENSE\_MLP\_FUSED");
 return env && env\[0\] && env\[0\] != '0';
 }();
 if (!dense\_mlp\_fused\_disabled) {
 const auto& gate\_buf = gb->get\_output\_buffer(layer.ffn\_gate\_weight);
 const auto& up\_buf = gb->get\_output\_buffer(layer.ffn\_up\_weight);
 const auto& down\_buf = gb->get\_output\_buffer(layer.ffn\_down\_weight);
 if (gate\_buf.precision == Precision::CQ4 && up\_buf.precision == Precision::CQ4 &&
 down\_buf.precision == Precision::CQ4 &&
 gate\_buf.group\_size > 0 && up\_buf.group\_size > 0 && down\_buf.group\_size > 0) {
 return gb->dense\_mlp\_tq\_fused(input, layer.ffn\_gate\_weight, layer.ffn\_up\_weight, layer.ffn\_down\_weight);
 }
 }
 auto gate = gb->gelu(gb->matmul(input, layer.ffn\_gate\_weight, true, backend));
 auto up = gb->matmul(input, layer.ffn\_up\_weight, true, backend);
 return gb->matmul(gb->multiply(gate, up), layer.ffn\_down\_weight, true, backend);
}

size\_t Gemma4Model::build\_moe(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx,
 ComputeBackend backend) const {
 const auto& layer = weight\_nodes\_.layers\[layer\_idx\];

 auto router\_logits = gb->matmul(input, layer.router\_proj, true, backend);
 auto topk\_result = gb->topk(router\_logits, config\_.num\_experts\_per\_tok);
 auto topk\_indices = gb->index(topk\_result, 0, 0);
 auto routing\_probs = gb->softmax(router\_logits);

 return gb->moe\_layer(input, routing\_probs, topk\_indices,
 layer.moe\_w1\_experts, layer.moe\_w3\_experts, layer.moe\_w2\_experts,
 config\_.num\_experts, config\_.num\_experts\_per\_tok,
 true, 1e-6f, 1.0f, Activation::GELU,
 layer.moe\_per\_expert\_scale);
}

size\_t Gemma4Model::build\_transformer\_block(CactusGraph\* gb, size\_t hidden, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache, size\_t position\_offset) {
 const auto& layer = weight\_nodes\_.layers\[layer\_idx\];

 auto normed = gb->rms\_norm(hidden, layer.input\_layernorm\_weight, config\_.layer\_norm\_eps);
 auto attn\_raw = build\_attention(gb, normed, layer\_idx, backend, use\_cache, position\_offset);
 auto attn = gb->rms\_norm(attn\_raw, layer.post\_attention\_layernorm\_weight, config\_.layer\_norm\_eps);
 auto residual = gb->add(hidden, attn);

 if (config\_.enable\_moe\_block) {
 auto h1 = gb->rms\_norm(residual, layer.pre\_feedforward\_layernorm\_weight, config\_.layer\_norm\_eps);
 h1 = build\_mlp(gb, h1, layer\_idx, backend);
 h1 = gb->rms\_norm(h1, layer.post\_ffn\_norm\_1, config\_.layer\_norm\_eps);

 auto h2 = gb->multiply(residual, layer.router\_scale);
 h2 = gb->rms\_norm(h2, layer.pre\_ffn\_norm\_2, config\_.layer\_norm\_eps);
 h2 = build\_moe(gb, h2, layer\_idx, backend);
 h2 = gb->rms\_norm(h2, layer.post\_ffn\_norm\_2, config\_.layer\_norm\_eps);

 auto combined = gb->rms\_norm(gb->add(h1, h2), layer.post\_feedforward\_layernorm\_weight, config\_.layer\_norm\_eps);
 return gb->add(residual, combined);
 }

 auto pre\_mlp = gb->rms\_norm(residual, layer.pre\_feedforward\_layernorm\_weight, config\_.layer\_norm\_eps);
 auto mlp\_raw = build\_mlp(gb, pre\_mlp, layer\_idx, backend);
 auto mlp = gb->rms\_norm(mlp\_raw, layer.post\_feedforward\_layernorm\_weight, config\_.layer\_norm\_eps);

 return gb->add(residual, mlp);
}

size\_t Gemma4Model::apply\_transformer\_layer(CactusGraph\* gb, size\_t hidden, size\_t pli, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache, size\_t pos\_offset) {
 hidden = build\_transformer\_block(gb, hidden, layer\_idx, backend, use\_cache, pos\_offset);
 if (config\_.hidden\_size\_per\_layer\_input > 0)
 hidden = build\_per\_layer\_input(gb, hidden, pli, layer\_idx, backend);
 if (weight\_nodes\_.layers\[layer\_idx\].layer\_scalar != 0)
 hidden = gb->multiply(hidden, weight\_nodes\_.layers\[layer\_idx\].layer\_scalar);
 return hidden;
}

size\_t Gemma4Model::build\_pli\_combined(CactusGraph\* gb, size\_t hidden, size\_t pli\_embed,
 size\_t seq\_len, ComputeBackend backend) {
 uint32\_t num\_layers = config\_.num\_layers;
 uint32\_t pli\_dim = config\_.hidden\_size\_per\_layer\_input;

 auto pli\_proj = gb->scalar\_multiply(gb->matmul(hidden, weight\_nodes\_.per\_layer\_model\_proj, true, backend),
 1.0f / std::sqrt(static\_cast(config\_.hidden\_dim)));
 pli\_proj = gb->reshape(pli\_proj, {seq\_len \* num\_layers, pli\_dim});
 pli\_proj = gb->rms\_norm(pli\_proj, weight\_nodes\_.per\_layer\_proj\_norm, config\_.layer\_norm\_eps);
 pli\_proj = gb->reshape(pli\_proj, {seq\_len, num\_layers \* pli\_dim});
 return gb->scalar\_multiply(gb->add(pli\_proj, pli\_embed), 1.0f / std::sqrt(2.0f));
}

std::pair Gemma4Model::build\_preamble\_and\_embed(CactusGraph\* gb, size\_t seq\_len, ComputeBackend backend,
 size\_t& token\_input, size\_t& pli\_input) {
 uint32\_t pli\_dim = config\_.hidden\_size\_per\_layer\_input;

 token\_input = gb->input({seq\_len}, Precision::FP32);
 auto hidden = gb->scalar\_multiply(gb->embedding(embedding\_node\_id\_, token\_input),
 std::sqrt(static\_cast(config\_.hidden\_dim)));

 pli\_input = gb->input({seq\_len}, Precision::FP32);
 auto pli\_embed = gb->scalar\_multiply(gb->embedding(weight\_nodes\_.embed\_tokens\_per\_layer, pli\_input),
 std::sqrt(static\_cast(pli\_dim)));
 auto pli\_combined = build\_pli\_combined(gb, hidden, pli\_embed, seq\_len, backend);

 return {hidden, pli\_combined};
}

void Gemma4Model::set\_token\_inputs(CactusGraph\* gb, size\_t token\_input, size\_t pli\_input,
 const std::vector& tokens) {
 std::vector input\_data(tokens.size());
 for (size\_t i = 0; i < tokens.size(); i++)
 input\_data\[i\] = static\_cast(tokens\[i\]);
 gb->set\_input(token\_input, input\_data.data(), Precision::FP32);
 gb->set\_input(pli\_input, input\_data.data(), Precision::FP32);
}

size\_t Gemma4Model::forward\_from\_embeddings(CactusGraph\* gb, size\_t hidden, const std::vector& pli\_tokens,
 size\_t seq\_len, ComputeBackend backend, bool use\_cache) {
 return forward\_from\_embeddings(gb, hidden, hidden, pli\_tokens, seq\_len, backend, use\_cache);
}

size\_t Gemma4Model::build\_pli\_combined\_from\_tokens(CactusGraph\* gb, size\_t hidden,
 const std::vector& pli\_tokens,
 size\_t seq\_len, ComputeBackend backend) {
 if (config\_.hidden\_size\_per\_layer\_input == 0)
 return 0;

 uint32\_t pli\_dim = config\_.hidden\_size\_per\_layer\_input;

 auto pli\_input = gb->input({seq\_len}, Precision::FP32);
 auto pli\_embed = gb->scalar\_multiply(gb->embedding(weight\_nodes\_.embed\_tokens\_per\_layer, pli\_input),
 std::sqrt(static\_cast(pli\_dim)));
 auto pli\_combined = build\_pli\_combined(gb, hidden, pli\_embed, seq\_len, backend);

 std::vector pli\_data(pli\_tokens.size());
 for (size\_t i = 0; i < pli\_tokens.size(); i++)
 pli\_data\[i\] = static\_cast(pli\_tokens\[i\]);
 gb->set\_input(pli\_input, pli\_data.data(), Precision::FP32);

 return pli\_combined;
}

size\_t Gemma4Model::forward\_from\_embeddings(CactusGraph\* gb, size\_t hidden, size\_t pli\_hidden\_source,
 const std::vector& pli\_tokens, size\_t seq\_len,
 ComputeBackend backend, bool use\_cache) {
 size\_t pos\_offset = use\_cache ? cache\_total\_seq\_len\_ : 0;

 std::fill(shared\_k\_nodes\_.begin(), shared\_k\_nodes\_.end(), 0);
 std::fill(shared\_v\_nodes\_.begin(), shared\_v\_nodes\_.end(), 0);

 if (config\_.hidden\_size\_per\_layer\_input == 0) {
 for (uint32\_t i = 0; i < config\_.num\_layers; i++)
 hidden = apply\_transformer\_layer(gb, hidden, 0, i, backend, use\_cache, pos\_offset);
 return gb->rms\_norm(hidden, weight\_nodes\_.output\_norm\_weight, config\_.layer\_norm\_eps);
 }

 auto pli\_combined = build\_pli\_combined\_from\_tokens(gb, pli\_hidden\_source, pli\_tokens, seq\_len, backend);

 for (uint32\_t i = 0; i < config\_.num\_layers; i++)
 hidden = apply\_transformer\_layer(gb, hidden, pli\_combined, i, backend, use\_cache, pos\_offset);

 return gb->rms\_norm(hidden, weight\_nodes\_.output\_norm\_weight, config\_.layer\_norm\_eps);
}

size\_t Gemma4Model::forward(const std::vector& tokens, bool use\_cache) {
 if (!initialized\_ \|\| !graph\_handle\_)
 throw std::runtime\_error("Model not initialized - call init() first");
 if (tokens.empty())
 throw std::runtime\_error("Token sequence cannot be empty");

 auto\* gb = static\_cast(graph\_handle\_);
 gb->soft\_reset();

 std::fill(shared\_k\_nodes\_.begin(), shared\_k\_nodes\_.end(), 0);
 std::fill(shared\_v\_nodes\_.begin(), shared\_v\_nodes\_.end(), 0);

 size\_t pos\_offset = use\_cache ? cache\_total\_seq\_len\_ : 0;
 auto backend = config\_.default\_backend == Config::Backend::CPU ? ComputeBackend::CPU : ComputeBackend::NPU;

 if (config\_.hidden\_size\_per\_layer\_input == 0) {
 auto token\_input = gb->input({tokens.size()}, Precision::FP32);
 auto hidden = gb->scalar\_multiply(gb->embedding(embedding\_node\_id\_, token\_input),
 std::sqrt(static\_cast(config\_.hidden\_dim)));

 for (uint32\_t i = 0; i < config\_.num\_layers; i++)
 hidden = apply\_transformer\_layer(gb, hidden, 0, i, backend, use\_cache, pos\_offset);

 std::vector input\_data(tokens.size());
 for (size\_t i = 0; i < tokens.size(); i++)
 input\_data\[i\] = static\_cast(tokens\[i\]);
 gb->set\_input(token\_input, input\_data.data(), Precision::FP32);
 return gb->rms\_norm(hidden, weight\_nodes\_.output\_norm\_weight, config\_.layer\_norm\_eps);
 }

 size\_t token\_input, pli\_input;
 auto hidden\_pli = build\_preamble\_and\_embed(gb, tokens.size(), backend, token\_input, pli\_input);
 size\_t hidden = hidden\_pli.first, pli = hidden\_pli.second;

 for (uint32\_t i = 0; i < config\_.num\_layers; i++)
 hidden = apply\_transformer\_layer(gb, hidden, pli, i, backend, use\_cache, pos\_offset);

 set\_token\_inputs(gb, token\_input, pli\_input, tokens);
 return gb->rms\_norm(hidden, weight\_nodes\_.output\_norm\_weight, config\_.layer\_norm\_eps);
}

size\_t Gemma4Model::forward\_split(const std::vector& tokens, bool use\_cache) {
 auto\* gb = static\_cast(graph\_handle\_);
 gb->soft\_reset();

 std::fill(shared\_k\_nodes\_.begin(), shared\_k\_nodes\_.end(), 0);
 std::fill(shared\_v\_nodes\_.begin(), shared\_v\_nodes\_.end(), 0);

 size\_t seq\_len = tokens.size();
 size\_t pos\_offset = use\_cache ? cache\_total\_seq\_len\_ : 0;
 auto backend = config\_.default\_backend == Config::Backend::CPU ? ComputeBackend::CPU : ComputeBackend::NPU;

 if (config\_.hidden\_size\_per\_layer\_input == 0) {
 auto token\_input = gb->input({seq\_len}, Precision::FP32);
 auto hidden = gb->scalar\_multiply(gb->embedding(embedding\_node\_id\_, token\_input),
 std::sqrt(static\_cast(config\_.hidden\_dim)));

 for (uint32\_t i = 0; i < first\_shared\_layer\_; i++)
 hidden = apply\_transformer\_layer(gb, hidden, 0, i, backend, use\_cache, pos\_offset);

 hidden = gb->index(hidden, seq\_len - 1, 0);
 hidden = gb->reshape(hidden, {1, config\_.hidden\_dim});

 size\_t shared\_pos\_offset = pos\_offset + seq\_len - 1;
 for (uint32\_t i = first\_shared\_layer\_; i < config\_.num\_layers; i++)
 hidden = apply\_transformer\_layer(gb, hidden, 0, i, backend, use\_cache, shared\_pos\_offset);

 std::vector input\_data(tokens.size());
 for (size\_t i = 0; i < tokens.size(); i++)
 input\_data\[i\] = static\_cast(tokens\[i\]);
 gb->set\_input(token\_input, input\_data.data(), Precision::FP32);
 return gb->rms\_norm(hidden, weight\_nodes\_.output\_norm\_weight, config\_.layer\_norm\_eps);
 }

 size\_t token\_input, pli\_input;
 auto hidden\_pli = build\_preamble\_and\_embed(gb, seq\_len, backend, token\_input, pli\_input);
 size\_t hidden = hidden\_pli.first, pli = hidden\_pli.second;

 for (uint32\_t i = 0; i < first\_shared\_layer\_; i++)
 hidden = apply\_transformer\_layer(gb, hidden, pli, i, backend, use\_cache, pos\_offset);

 hidden = gb->index(hidden, seq\_len - 1, 0);
 hidden = gb->reshape(hidden, {1, config\_.hidden\_dim});
 auto pli\_last = gb->index(pli, seq\_len - 1, 0);
 pli\_last = gb->reshape(pli\_last, {1, config\_.num\_layers \* config\_.hidden\_size\_per\_layer\_input});

 size\_t shared\_pos\_offset = pos\_offset + seq\_len - 1;
 for (uint32\_t i = first\_shared\_layer\_; i < config\_.num\_layers; i++)
 hidden = apply\_transformer\_layer(gb, hidden, pli\_last, i, backend, use\_cache, shared\_pos\_offset);

 set\_token\_inputs(gb, token\_input, pli\_input, tokens);
 return gb->rms\_norm(hidden, weight\_nodes\_.output\_norm\_weight, config\_.layer\_norm\_eps);
}

void Gemma4Model::prefill(const std::vector& tokens, size\_t chunk\_size, const std::string& profile\_file) {
 if (tokens.empty())
 return;

 if (has\_npu\_prefill()) {
 size\_t npu\_chunk\_size = static\_cast(npu\_prefill\_->get\_chunk\_size());
 if (tokens.size() > npu\_chunk\_size) {
 Model::prefill(tokens, chunk\_size, profile\_file);
 return;
 }
 }

 static constexpr size\_t SPLIT\_PREFILL\_MIN\_TOKENS = 32;
 bool use\_split = config\_.num\_kv\_shared\_layers > 0
 && tokens.size() >= SPLIT\_PREFILL\_MIN\_TOKENS
 && !std::getenv("CACTUS\_DISABLE\_SPLIT\_PREFILL");

 if (!use\_split) {
 Model::prefill(tokens, chunk\_size, profile\_file);
 return;
 }

 auto\* gb = static\_cast(graph\_handle\_);
 auto process\_chunk = \[&\](const std::vector& chunk) {
 forward\_split(chunk, true);
 gb->execute(profile\_file);
 cache\_total\_seq\_len\_ += chunk.size();
 };

 if (tokens.size() <= chunk\_size) {
 process\_chunk(tokens);
 return;
 }

 size\_t num\_full\_chunks = (tokens.size() - 1) / chunk\_size;
 for (size\_t i = 0; i < num\_full\_chunks; ++i) {
 size\_t start = i \* chunk\_size;
 std::vector chunk(tokens.begin() + start, tokens.begin() + start + chunk\_size);
 if (i == 1)
 gb->set\_prefill\_mode(true);
 process\_chunk(chunk);
 }

 gb->set\_prefill\_mode(false);
 size\_t final\_start = num\_full\_chunks \* chunk\_size;
 process\_chunk(std::vector(tokens.begin() + final\_start, tokens.end()));
}

}
}