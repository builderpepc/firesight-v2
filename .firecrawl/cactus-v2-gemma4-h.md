#pragma once

#include "../model.h"

bool test\_gemma4\_vision(bool expect\_npu);
bool test\_gemma4\_audio(bool expect\_npu);

namespace cactus {
namespace engine {

class Gemma4Model : public Model {
 friend class Gemma4MmModel;
public:
 Gemma4Model();
 explicit Gemma4Model(const Config& config);
 ~Gemma4Model() override = default;

protected:
 size\_t build\_attention(CactusGraph\* gb, size\_t normalized\_input, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) override;

 size\_t build\_mlp(CactusGraph\* gb, size\_t normalized\_h, uint32\_t layer\_idx,
 ComputeBackend backend) const override;

 size\_t build\_moe(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx,
 ComputeBackend backend) const;

 size\_t build\_transformer\_block(CactusGraph\* gb, size\_t hidden, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) override;

 size\_t forward(const std::vector& tokens, bool use\_cache = false) override;
 void prefill(const std::vector& tokens, size\_t chunk\_size = 256, const std::string& profile\_file = "") override;
 void load\_weights\_to\_graph(CactusGraph\* gb) override;
 void post\_init() override;
 std::vector get\_kv\_layer\_dims() const override;
 std::vector get\_kv\_layer\_heads() const override;
 std::vector get\_kv\_layer\_windows() const override;
 void compact\_kv\_cache() override;

 size\_t forward\_from\_embeddings(CactusGraph\* gb, size\_t hidden, const std::vector& pli\_tokens,
 size\_t seq\_len, ComputeBackend backend, bool use\_cache);
 size\_t forward\_from\_embeddings(CactusGraph\* gb, size\_t hidden, size\_t pli\_hidden\_source,
 const std::vector& pli\_tokens, size\_t seq\_len,
 ComputeBackend backend, bool use\_cache);
 size\_t build\_pli\_combined\_from\_tokens(CactusGraph\* gb, size\_t hidden,
 const std::vector& pli\_tokens,
 size\_t seq\_len, ComputeBackend backend);

private:
 size\_t forward\_split(const std::vector& tokens, bool use\_cache);

 std::pair build\_preamble\_and\_embed(CactusGraph\* gb, size\_t seq\_len, ComputeBackend backend,
 size\_t& token\_input, size\_t& pli\_input);

 void set\_token\_inputs(CactusGraph\* gb, size\_t token\_input, size\_t pli\_input,
 const std::vector& tokens);

 size\_t build\_pli\_combined(CactusGraph\* gb, size\_t hidden, size\_t pli\_embed,
 size\_t seq\_len, ComputeBackend backend);

 size\_t build\_per\_layer\_input(CactusGraph\* gb, size\_t hidden, size\_t pli\_combined, uint32\_t layer\_idx,
 ComputeBackend backend) const;

 bool is\_global\_layer(uint32\_t idx) const;
 size\_t apply\_partial\_rope(CactusGraph\* gb, size\_t tensor, size\_t head\_dim, size\_t rot\_dim,
 float rope\_freq, size\_t position\_offset);
 size\_t apply\_transformer\_layer(CactusGraph\* gb, size\_t hidden, size\_t pli, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache, size\_t pos\_offset);

 struct WeightNodeIDs {
 size\_t output\_weight;
 size\_t output\_norm\_weight;

 size\_t embed\_tokens\_per\_layer;
 size\_t per\_layer\_model\_proj;
 size\_t per\_layer\_proj\_norm;

 struct LayerWeights {
 size\_t attn\_q\_weight;
 size\_t attn\_k\_weight;
 size\_t attn\_v\_weight;
 size\_t attn\_output\_weight;
 size\_t input\_layernorm\_weight;
 size\_t attn\_q\_norm\_weight;
 size\_t attn\_k\_norm\_weight;
 size\_t pre\_feedforward\_layernorm\_weight;
 size\_t post\_feedforward\_layernorm\_weight;
 size\_t ffn\_gate\_weight;
 size\_t ffn\_up\_weight;
 size\_t ffn\_down\_weight;
 size\_t post\_attention\_layernorm\_weight;
 size\_t per\_layer\_gate;
 size\_t per\_layer\_proj;
 size\_t post\_per\_layer\_norm;
 size\_t layer\_scalar;

 std::vector moe\_w1\_experts;
 std::vector moe\_w3\_experts;
 std::vector moe\_w2\_experts;
 size\_t moe\_per\_expert\_scale = 0;
 size\_t router\_proj = 0;
 size\_t router\_scale = 0;
 size\_t post\_ffn\_norm\_1 = 0;
 size\_t pre\_ffn\_norm\_2 = 0;
 size\_t post\_ffn\_norm\_2 = 0;
 };

 std::vector layers;
 } weight\_nodes\_;

 uint32\_t first\_shared\_layer\_ = 0;
 std::vector kv\_share\_map\_;
 std::vector shared\_k\_nodes\_;
 std::vector shared\_v\_nodes\_;

 std::vector<\_\_fp16> v\_norm\_ones\_weight\_;
 size\_t v\_norm\_ones\_node\_ = 0;
 size\_t v\_norm\_ones\_global\_node\_ = 0;
};

class Gemma4VisionModel : public Model {
 friend class Gemma4MmModel;
public:
 struct PreprocessedImage {
 std::vector pixel\_values;
 size\_t height;
 size\_t width;
 size\_t patch\_height;
 size\_t patch\_width;
 size\_t num\_patches;
 };

 Gemma4VisionModel();
 explicit Gemma4VisionModel(const Config& config);
 ~Gemma4VisionModel() override = default;

 PreprocessedImage preprocess\_image(const std::string& image\_path);
 size\_t forward\_vision(CactusGraph\* gb, const PreprocessedImage& img, ComputeBackend backend);
 size\_t build\_vision\_projector(CactusGraph\* gb, size\_t vision\_features, ComputeBackend backend);

protected:
 size\_t forward(const std::vector&, bool) override {
 throw std::runtime\_error("Gemma4VisionModel: use forward\_vision() instead");
 }
 size\_t build\_attention(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) override {
 throw std::runtime\_error("Gemma4VisionModel: build\_attention unused");
 }
 size\_t build\_mlp(CactusGraph\*, size\_t, uint32\_t, ComputeBackend) const override {
 throw std::runtime\_error("Gemma4VisionModel: build\_mlp unused");
 }
 size\_t build\_transformer\_block(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) override {
 throw std::runtime\_error("Gemma4VisionModel: build\_transformer\_block unused");
 }
 void load\_weights\_to\_graph(CactusGraph\* gb) override;

private:
 size\_t build\_vision\_patch\_embedding(CactusGraph\* gb, const PreprocessedImage& img, ComputeBackend backend);
 size\_t build\_vision\_attention(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx,
 size\_t cos\_node, size\_t sin\_node,
 size\_t attn\_mask\_node, ComputeBackend backend);
 size\_t build\_vision\_mlp(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx, ComputeBackend backend);
 size\_t build\_vision\_transformer\_block(CactusGraph\* gb, size\_t hidden, uint32\_t layer\_idx,
 size\_t cos\_node, size\_t sin\_node,
 size\_t attn\_mask\_node, ComputeBackend backend);
 size\_t build\_vision\_pooler(CactusGraph\* gb, size\_t hidden, const PreprocessedImage& img, ComputeBackend backend);
 std::pair build\_2d\_rope\_nodes(CactusGraph\* gb, const PreprocessedImage& img, size\_t max\_patches);
 size\_t build\_padding\_mask(CactusGraph\* gb, size\_t num\_real, size\_t max\_patches);

 struct VisionWeightNodes {
 size\_t patch\_input\_proj = 0;
 size\_t position\_table = 0;

 struct LayerWeights {
 size\_t attn\_q\_weight = 0;
 size\_t attn\_k\_weight = 0;
 size\_t attn\_v\_weight = 0;
 size\_t attn\_output\_weight = 0;
 size\_t attn\_q\_norm = 0;
 size\_t attn\_k\_norm = 0;
 size\_t input\_layernorm = 0;
 size\_t post\_attention\_layernorm = 0;
 size\_t pre\_feedforward\_layernorm = 0;
 size\_t post\_feedforward\_layernorm = 0;
 size\_t mlp\_gate\_proj = 0;
 size\_t mlp\_up\_proj = 0;
 size\_t mlp\_down\_proj = 0;
 size\_t layer\_scalar = 0;
 };

 std::vector layers;
 size\_t embed\_vision\_proj = 0;
 size\_t post\_proj\_norm = 0;
 } vision\_weights\_;

 std::vector<\_\_fp16> vision\_v\_norm\_ones\_;
 size\_t vision\_v\_norm\_ones\_node\_ = 0;
 std::vector<\_\_fp16> post\_proj\_norm\_ones\_;

 std::unique\_ptr npu\_encoder\_;
 bool use\_npu\_encoder\_ = false;
 bool disable\_npu\_ = false;

 friend bool ::test\_gemma4\_vision(bool);
};

class Gemma4AudioModel : public Model {
 friend class Gemma4MmModel;
public:
 Gemma4AudioModel();
 explicit Gemma4AudioModel(const Config& config);
 ~Gemma4AudioModel() override = default;

 struct ConformerContext {
 size\_t timing\_fp16 = 0;
 size\_t front\_pad = 0;
 size\_t back\_pad = 0;
 size\_t seq\_len = 0;
 };

 size\_t forward\_audio(CactusGraph\* gb, const std::vector& mel\_features,
 size\_t num\_frames, ComputeBackend backend);

 size\_t build\_audio\_projector(CactusGraph\* gb, size\_t audio\_features, ComputeBackend backend);

 size\_t build\_sscp(CactusGraph\* gb, const std::vector& mel\_features,
 size\_t num\_frames, ComputeBackend backend);

 ConformerContext build\_conformer\_context(CactusGraph\* gb, size\_t sscp\_output);

 size\_t build\_conformer\_ffw(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx,
 bool is\_end, ComputeBackend backend);
 size\_t build\_conformer\_attention(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx,
 const ConformerContext& ctx, ComputeBackend backend);
 size\_t build\_conformer\_lconv1d(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx,
 ComputeBackend backend);
 size\_t build\_conformer\_block(CactusGraph\* gb, size\_t hidden, uint32\_t layer\_idx,
 const ConformerContext& ctx, ComputeBackend backend);

 struct AudioWeightNodes {
 size\_t sscp\_conv0\_weight = 0;
 size\_t sscp\_conv0\_norm = 0;
 size\_t sscp\_conv1\_weight = 0;
 size\_t sscp\_conv1\_norm = 0;
 size\_t sscp\_input\_proj = 0;

 struct ClipBounds {
 float in\_min = -1e10f, in\_max = 1e10f;
 float out\_min = -1e10f, out\_max = 1e10f;
 };

 struct ConformerLayerWeights {
 size\_t ffw\_start\_1 = 0, ffw\_start\_2 = 0;
 ClipBounds ffw\_start\_1\_clip, ffw\_start\_2\_clip;
 size\_t ffw\_start\_pre\_norm = 0, ffw\_start\_post\_norm = 0;
 size\_t attn\_q = 0, attn\_k = 0, attn\_v = 0;
 ClipBounds attn\_q\_clip, attn\_k\_clip, attn\_v\_clip;
 size\_t attn\_per\_dim\_scale = 0;
 size\_t attn\_rel\_pos\_proj = 0;
 size\_t attn\_post = 0;
 ClipBounds attn\_post\_clip;
 size\_t attn\_pre\_norm = 0, attn\_post\_norm = 0;
 size\_t lconv\_start = 0, lconv\_depthwise = 0, lconv\_end = 0;
 ClipBounds lconv\_start\_clip, lconv\_end\_clip;
 size\_t lconv\_pre\_norm = 0, lconv\_conv\_norm = 0;
 size\_t ffw\_end\_1 = 0, ffw\_end\_2 = 0;
 ClipBounds ffw\_end\_1\_clip, ffw\_end\_2\_clip;
 size\_t ffw\_end\_pre\_norm = 0, ffw\_end\_post\_norm = 0;
 size\_t block\_norm = 0;
 };
 std::vector layers;

 size\_t output\_proj = 0;
 size\_t output\_proj\_bias = 0;

 size\_t embed\_audio\_proj = 0;
 } audio\_weights\_;

 std::vector<\_\_fp16> audio\_proj\_norm\_ones\_;
 size\_t audio\_proj\_norm\_ones\_node\_ = 0;

 std::unique\_ptr npu\_encoder\_;
 bool use\_npu\_encoder\_ = false;
 bool disable\_npu\_ = false;
 std::vector<\_\_fp16> npu\_audio\_input\_scratch\_;
 std::vector<\_\_fp16> npu\_audio\_output\_scratch\_;
 std::vector<\_\_fp16> npu\_audio\_reorder\_scratch\_;

 friend bool ::test\_gemma4\_audio(bool);

protected:
 size\_t forward(const std::vector&, bool) override {
 throw std::runtime\_error("Gemma4AudioModel: use forward\_audio() instead");
 }
 size\_t build\_attention(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) override {
 throw std::runtime\_error("Gemma4AudioModel: build\_attention unused");
 }
 size\_t build\_mlp(CactusGraph\*, size\_t, uint32\_t, ComputeBackend) const override {
 throw std::runtime\_error("Gemma4AudioModel: build\_mlp unused");
 }
 size\_t build\_transformer\_block(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) override {
 throw std::runtime\_error("Gemma4AudioModel: build\_transformer\_block unused");
 }
 void load\_weights\_to\_graph(CactusGraph\* gb) override;
};

class Gemma4MmModel : public Model {
public:
 Gemma4MmModel();
 explicit Gemma4MmModel(const Config& config);
 ~Gemma4MmModel() override = default;

 bool init(const std::string& model\_folder, size\_t context\_size,
 const std::string& system\_prompt = "", bool do\_warmup = true) override;

 size\_t forward(const std::vector& tokens, bool use\_cache = false) override;

 uint32\_t decode(const std::vector& tokens,
 float temperature = -1.0f, float top\_p = -1.0f, size\_t top\_k = 0,
 const std::string& profile\_file = "", float\* out\_entropy = nullptr,
 float min\_p = 0.15f, float repetition\_penalty = 1.1f) override;

 void prefill(const std::vector& tokens, size\_t chunk\_size = 256,
 const std::string& profile\_file = "") override;

 void prefill\_with\_images(const std::vector& tokens, const std::vector& image\_paths,
 const std::string& profile\_file = "") override;

 uint32\_t decode\_with\_images(
 const std::vector& tokens,
 const std::vector& image\_paths,
 float temperature = -1.0f, float top\_p = -1.0f, size\_t top\_k = 0,
 const std::string& profile\_file = "", float\* out\_entropy = nullptr,
 float min\_p = 0.15f, float repetition\_penalty = 1.1f) override;

 uint32\_t decode\_with\_audio(
 const std::vector& tokens,
 const std::vector& audio\_features,
 float temperature = 0.0f, float top\_p = 0.0f, size\_t top\_k = 0,
 const std::string& profile\_file = "", float\* out\_entropy = nullptr,
 float min\_p = 0.15f, float repetition\_penalty = 1.1f,
 float\* out\_token\_time\_start = nullptr, float\* out\_token\_time\_end = nullptr) override;

 uint32\_t decode\_with\_media(
 const std::vector& tokens,
 const std::vector& image\_paths,
 const std::vector& audio\_features,
 float temperature = -1.0f, float top\_p = -1.0f, size\_t top\_k = 0,
 const std::string& profile\_file = "", float\* out\_entropy = nullptr,
 float min\_p = 0.15f, float repetition\_penalty = 1.1f);

 void reset\_cache() override;
 std::vector get\_image\_embeddings(const std::string& image\_path) override;
 std::vector get\_audio\_embeddings(const std::vector& audio\_features) override;
 void compact\_kv\_cache() override;
 void remove\_thinking\_tokens(const std::vector>& ranges) override;

 void set\_tool\_constraints(const std::vector& tools) override;
 void clear\_tool\_constraints() override;
 void update\_tool\_constraints(uint32\_t token\_id) override;

protected:
 size\_t build\_attention(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) override;
 size\_t build\_mlp(CactusGraph\*, size\_t, uint32\_t, ComputeBackend) const override;
 size\_t build\_transformer\_block(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) override;
 void load\_weights\_to\_graph(CactusGraph\* gb) override;

private:
 struct ForwardResult {
 size\_t final\_hidden\_node;
 size\_t seq\_len;
 };

 ForwardResult forward\_multimodal(CactusGraph\* gb, const std::vector& tokens,
 const std::vector& image\_paths,
 const std::vector\\* audio\_features,
 size\_t audio\_num\_frames,
 ComputeBackend backend, bool use\_cache);

 uint32\_t decode\_multimodal(const std::vector& tokens,
 const std::vector& image\_paths,
 const std::vector\\* audio\_features,
 size\_t audio\_num\_frames,
 float temperature, float top\_p, size\_t top\_k,
 const std::string& profile\_file, float\* out\_entropy,
 float min\_p, float repetition\_penalty);

public:
 struct MultimodalInputs {
 size\_t hidden\_node = 0;
 size\_t pli\_hidden\_source\_node = 0;
 std::vector pli\_tokens;
 size\_t seq\_len = 0;
 };

 const Gemma4VisionModel& vision\_encoder() const { return vision\_encoder\_; }
 Gemma4VisionModel& vision\_encoder() { return vision\_encoder\_; }
 const Gemma4AudioModel& audio\_encoder() const { return audio\_encoder\_; }
 Gemma4AudioModel& audio\_encoder() { return audio\_encoder\_; }
 const Gemma4Model& language\_model() const { return language\_model\_; }
 Gemma4Model& language\_model() { return language\_model\_; }
 MultimodalInputs build\_multimodal\_inputs(
 CactusGraph\* gb, const std::vector& tokens,
 const std::vector& image\_paths,
 const std::vector\\* audio\_features,
 size\_t audio\_num\_frames,
 ComputeBackend backend);

private:
 Gemma4VisionModel vision\_encoder\_;
 Gemma4AudioModel audio\_encoder\_;
 Gemma4Model language\_model\_;
};

}
}