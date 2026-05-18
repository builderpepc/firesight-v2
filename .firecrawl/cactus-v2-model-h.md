#pragma once

#include "../src/engine.h"

namespace cactus {
namespace engine {

class QwenModel : public Model {
public:
 QwenModel();
 explicit QwenModel(const Config& config);
 ~QwenModel() override = default;

protected:
 size\_t build\_attention(CactusGraph\* gb, size\_t normalized\_input, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) override;
 size\_t build\_mlp(CactusGraph\* gb, size\_t normalized\_h, uint32\_t layer\_idx,
 ComputeBackend backend) const override;
 size\_t build\_transformer\_block(CactusGraph\* gb, size\_t hidden, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) override;
 size\_t forward(const std::vector& tokens, bool use\_cache = false) override;
 void load\_weights\_to\_graph(CactusGraph\* gb) override;

private:
 struct WeightNodeIDs {
 size\_t output\_weight;
 size\_t output\_norm\_weight;

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
 };

 std::vector layers;
 } weight\_nodes\_;
};

class Lfm2VlModel;

class Siglip2VisionModel : public Model {
 friend class Lfm2VlModel;

public:
 struct VisionEmbeddingResult {
 size\_t combined\_embeddings;
 std::vector tile\_embeddings;
 };

 Siglip2VisionModel();
 explicit Siglip2VisionModel(const Config& cfg);
 ~Siglip2VisionModel() override = default;

 virtual size\_t forward\_vision(const Siglip2Preprocessor::PreprocessedImage& preprocessed\_image);
 virtual size\_t forward\_vision(CactusGraph\* gb,
 const Siglip2Preprocessor::PreprocessedImage& preprocessed\_image,
 ComputeBackend backend);
 std::vector get\_image\_embedding(const std::string& image\_path);
 Siglip2Preprocessor& get\_preprocessor() { return preprocessor\_; }
 const Siglip2Preprocessor& get\_preprocessor() const { return preprocessor\_; }

protected:
 VisionEmbeddingResult build\_vision\_embeddings(CactusGraph\* gb,
 const Siglip2Preprocessor::PreprocessedImage& preprocessed\_image,
 ComputeBackend backend);
 size\_t build\_vision\_transformer\_layer(CactusGraph\* gb, size\_t hidden\_states, uint32\_t layer\_idx,
 ComputeBackend backend);
 size\_t build\_vision\_attention(CactusGraph\* gb, size\_t hidden\_states, uint32\_t layer\_idx,
 ComputeBackend backend);
 size\_t build\_vision\_mlp(CactusGraph\* gb, size\_t hidden\_states, uint32\_t layer\_idx,
 ComputeBackend backend);
 void ensure\_cpu\_vision\_weights\_loaded(CactusGraph\* gb);

 void load\_weights\_to\_graph(CactusGraph\* gb) override;
 size\_t forward(const std::vector& tokens, bool use\_cache = false) override;
 size\_t build\_attention(CactusGraph\* gb, size\_t normalized\_input, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) override;
 size\_t build\_mlp(CactusGraph\* gb, size\_t normalized\_h, uint32\_t layer\_idx,
 ComputeBackend backend) const override;
 size\_t build\_transformer\_block(CactusGraph\* gb, size\_t hidden, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) override;

 struct VisionWeightNodeIDs {
 size\_t patch\_embedding\_weight;
 size\_t patch\_embedding\_bias;
 size\_t position\_embedding;
 size\_t post\_layernorm\_weight;
 size\_t post\_layernorm\_bias;

 struct VisionLayerWeights {
 size\_t attn\_q\_weight;
 size\_t attn\_k\_weight;
 size\_t attn\_v\_weight;
 size\_t attn\_output\_weight;
 size\_t attn\_q\_bias;
 size\_t attn\_k\_bias;
 size\_t attn\_v\_bias;
 size\_t attn\_output\_bias;
 size\_t layer\_norm1\_weight;
 size\_t layer\_norm1\_bias;
 size\_t layer\_norm2\_weight;
 size\_t layer\_norm2\_bias;
 size\_t mlp\_fc1\_weight;
 size\_t mlp\_fc1\_bias;
 size\_t mlp\_fc2\_weight;
 size\_t mlp\_fc2\_bias;
 };

 std::vector vision\_layers;
 } vision\_weight\_nodes\_;

 Siglip2Preprocessor preprocessor\_;
 std::unique\_ptr npu\_encoder\_;
 bool use\_npu\_encoder\_ = false;
 bool cpu\_vision\_weights\_loaded\_ = false;
};

class LFM2Model : public Model {
 friend class Lfm2VlModel;

public:
 LFM2Model();
 explicit LFM2Model(const Config& config);
 ~LFM2Model() override = default;

 bool is\_cache\_empty() const;
 void update\_kv\_cache(CactusGraph\* gb, size\_t seq\_len);
 bool init(const std::string& model\_folder, size\_t context\_size,
 const std::string& system\_prompt = "", bool do\_warmup = true) override;
 bool init(CactusGraph\* external\_graph, const std::string& model\_folder, size\_t context\_size,
 const std::string& system\_prompt = "", bool do\_warmup = true) override;

protected:
 using Model::forward;
 size\_t build\_attention(CactusGraph\* gb, size\_t normalized\_input, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) override;
 size\_t build\_conv1d(CactusGraph\* gb, size\_t input, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache);
 size\_t build\_mlp(CactusGraph\* gb, size\_t normalized\_h, uint32\_t layer\_idx,
 ComputeBackend backend) const override;
 size\_t build\_transformer\_block(CactusGraph\* gb, size\_t hidden, uint32\_t layer\_idx,
 ComputeBackend backend, bool use\_cache = false, size\_t position\_offset = 0) override;
 size\_t forward(const std::vector& tokens, bool use\_cache = false) override;
 size\_t forward(CactusGraph\* gb, const std::vector& tokens, ComputeBackend backend, bool use\_cache = false);
 size\_t forward(CactusGraph\* gb, size\_t input\_embeddings, size\_t seq\_len, ComputeBackend backend, bool use\_cache = false);
 void post\_init() override;
 void post\_execute\_updates(CactusGraph\* gb, size\_t seq\_len) override;
 void reset\_cache() override;
 void load\_weights\_to\_graph(CactusGraph\* gb) override;

private:
 struct WeightNodeIDs {
 size\_t output\_weight;
 size\_t output\_norm\_weight;

 struct LayerWeights {
 size\_t attn\_q\_weight;
 size\_t attn\_k\_weight;
 size\_t attn\_v\_weight;
 size\_t attn\_output\_weight;
 size\_t attn\_q\_norm\_weight;
 size\_t attn\_k\_norm\_weight;
 size\_t conv\_depthwise\_weight;
 size\_t conv\_in\_proj\_weight;
 size\_t conv\_out\_proj\_weight;
 size\_t input\_layernorm\_weight;
 size\_t post\_attention\_layernorm\_weight;
 size\_t ffn\_gate\_weight;
 size\_t ffn\_up\_weight;
 size\_t ffn\_down\_weight;
 };

 enum class LayerType : uint8\_t { ATTENTION, CONV };

 struct LayerEntry {
 LayerType type;
 LayerWeights weights;
 };

 std::vector layers;
 } weight\_nodes\_;

 ConvCache conv\_cache\_;
 std::vector conv\_cache\_bx\_nodes\_;
 bool last\_forward\_used\_cache\_ = false;
};

class Lfm2VlModel : public Model {
public:
 Lfm2VlModel();
 explicit Lfm2VlModel(const Config& config);
 ~Lfm2VlModel() override = default;

 bool init(const std::string& model\_folder, size\_t context\_size,
 const std::string& system\_prompt = "", bool do\_warmup = true) override;
 size\_t forward(const std::vector& tokens, bool use\_cache = false) override;
 uint32\_t decode(const std::vector& tokens,
 float temperature = -1.0f,
 float top\_p = -1.0f,
 size\_t top\_k = 0,
 const std::string& profile\_file = "",
 float\* out\_entropy = nullptr,
 float min\_p = 0.15f,
 float repetition\_penalty = 1.1f) override;
 void prefill(const std::vector& tokens, size\_t chunk\_size = 256,
 const std::string& profile\_file = "") override;
 void prefill\_with\_images(const std::vector& tokens,
 const std::vector& image\_paths,
 const std::string& profile\_file = "") override;
 uint32\_t decode\_with\_images(const std::vector& tokens,
 const std::vector& image\_paths,
 float temperature = -1.0f,
 float top\_p = -1.0f,
 size\_t top\_k = 0,
 const std::string& profile\_file = "",
 float\* out\_entropy = nullptr,
 float min\_p = 0.15f,
 float repetition\_penalty = 1.1f) override;
 void reset\_cache() override;
 std::vector get\_image\_embeddings(const std::string& image\_path) override;

protected:
 size\_t build\_attention(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) override;
 size\_t build\_mlp(CactusGraph\*, size\_t, uint32\_t, ComputeBackend) const override;
 size\_t build\_transformer\_block(CactusGraph\*, size\_t, uint32\_t, ComputeBackend, bool, size\_t) override;
 void load\_weights\_to\_graph(CactusGraph\* gb) override;

private:
 struct ProjectedTileFeature {
 size\_t node\_id;
 size\_t token\_count;
 };

 struct TextEmbeddingInput {
 size\_t input\_node;
 std::vector tokens;
 };

 struct MergedEmbeddingResult {
 size\_t node\_id;
 size\_t seq\_len;
 };

 struct ForwardImageResult {
 size\_t final\_hidden\_node;
 size\_t seq\_len;
 };

 std::vector get\_image\_features(
 CactusGraph\* gb,
 const Siglip2Preprocessor::PreprocessedImage& preprocessed\_image,
 ComputeBackend backend);
 ForwardImageResult forward\_images(CactusGraph\* gb,
 const std::vector& tokens,
 const std::vector& image\_paths,
 ComputeBackend backend,
 bool use\_cache);
 size\_t build\_multimodal\_projector(CactusGraph\* gb,
 size\_t image\_features,
 size\_t tile\_h,
 size\_t tile\_w,
 ComputeBackend backend);
 size\_t pixel\_unshuffle(CactusGraph\* gb, size\_t hidden\_states, size\_t height, size\_t width, size\_t channels);
 MergedEmbeddingResult merge\_image\_text\_embeddings(
 CactusGraph\* gb,
 const std::vector& tokens,
 const std::vector>& image\_embedding\_nodes,
 std::vector& text\_embedding\_inputs);

 Siglip2VisionModel vision\_tower\_;
 LFM2Model language\_model\_;
 Siglip2Preprocessor preprocessor\_;

 struct ProjectorWeights {
 size\_t layer\_norm\_weight;
 size\_t layer\_norm\_bias;
 size\_t linear\_1\_weight;
 size\_t linear\_1\_bias;
 size\_t linear\_2\_weight;
 size\_t linear\_2\_bias;
 } projector\_weights\_;

 bool vision\_weights\_loaded\_ = false;
 bool language\_weights\_loaded\_ = false;
 bool image\_prefill\_completed\_ = false;
 size\_t last\_token\_count\_ = 0;
};

} // namespace engine
} // namespace cactus

#include "gemma4/model\_gemma4.h"