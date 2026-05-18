[![Hugging Face's logo](https://huggingface.co/front/assets/huggingface_logo-noborder.svg)Hugging Face](https://huggingface.co/)

- [Models](https://huggingface.co/models)
- [Datasets](https://huggingface.co/datasets)
- [Spaces](https://huggingface.co/spaces)
- [Buckets new](https://huggingface.co/storage)
- [Docs](https://huggingface.co/docs)
- [Enterprise](https://huggingface.co/enterprise)
- [Pricing](https://huggingface.co/pricing)

- * * *

- [Log In](https://huggingface.co/login)
- [Sign Up](https://huggingface.co/join)

[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)](https://huggingface.co/Cactus-Compute "Cactus Compute, Inc.")

[**Cactus Compute, Inc.**](https://huggingface.co/Cactus-Compute "Cactus Compute, Inc.")

[Team](https://huggingface.co/enterprise)

company

[https://cactuscompute.com](https://cactuscompute.com/)

[Activity Feed](https://huggingface.co/organizations/Cactus-Compute/activity/all)

Follow

![](https://cdn-avatars.huggingface.co/v1/production/uploads/noauth/4mrJzYEqEb0lCw4e27dJ7.png)

![](https://huggingface.co/avatars/983cf59cd950c2ccf4112a58d26abcdf.svg)

![](https://cdn-avatars.huggingface.co/v1/production/uploads/no-auth/v73DO-Za9LAor1FDMnCcc.png)

96

### AI & ML interests

Framework for on-device AI inference.

### Recent Activity

[![](https://huggingface.co/api/users/hmunachii/avatar)](https://huggingface.co/hmunachii)

[hmunachii](https://huggingface.co/hmunachii)updated a modelabout 11 hours ago

[Cactus-Compute/needle](https://huggingface.co/Cactus-Compute/needle)

[![](https://huggingface.co/api/users/hmunachii/avatar)](https://huggingface.co/hmunachii)

[hmunachii](https://huggingface.co/hmunachii)published a dataset1 day ago

[Cactus-Compute/needle-tokenizer](https://huggingface.co/datasets/Cactus-Compute/needle-tokenizer)

[![](https://huggingface.co/api/users/hmunachii/avatar)](https://huggingface.co/hmunachii)

[hmunachii](https://huggingface.co/hmunachii)published a model1 day ago

[Cactus-Compute/needle](https://huggingface.co/Cactus-Compute/needle)

[View all activity](https://huggingface.co/organizations/Cactus-Compute/activity/all "View all activity")

### Team members 7

[![Henry Ndubuaku's profile picture](https://cdn-avatars.huggingface.co/v1/production/uploads/noauth/oh94KsA5XfZ16EHomHiQe.jpeg)](https://huggingface.co/hmunachii)[![Roman Shemet's profile picture](https://cdn-avatars.huggingface.co/v1/production/uploads/no-auth/71D0eQ2DNk7pD1FptcmZp.png)](https://huggingface.co/rshemet)[![Jakub Mroz's profile picture](https://huggingface.co/avatars/11d2d4e7de4c6a0d80192858bec33686.svg)](https://huggingface.co/jakmro)[![Satyajit Kumar's profile picture](https://huggingface.co/avatars/c89fdf28a9fbf7ecc62c083fcaa7ab38.svg)](https://huggingface.co/ammesatyajit)[![Karen Mosoyan's profile picture](https://huggingface.co/avatars/9efaddd6b0a81fe6289e43acd8eaec24.svg)](https://huggingface.co/kmoss)[![Parkirat Sandhu's profile picture](https://cdn-avatars.huggingface.co/v1/production/uploads/no-auth/pls_OjYgdy1_ZbrUi_Q4P.png)](https://huggingface.co/ParkiratS)[![Noah Cylich's profile picture](https://huggingface.co/avatars/3f931ddc82470940e0804fb0babfc842.svg)](https://huggingface.co/ncylich)

Organization Card

[Community](https://huggingface.co/spaces/Cactus-Compute/README/discussions) [About org cards](https://huggingface.co/docs/hub/organizations-cards)

# Cactus

[![Docs](https://img.shields.io/badge/Docs-555?style=for-the-badge&logo=readthedocs&logoColor=white)](https://cactus-compute.github.io/cactus/)[![Website](https://img.shields.io/badge/Website-555?style=for-the-badge&logo=safari&logoColor=white)](https://cactuscompute.com/)[![GitHub](https://img.shields.io/badge/GitHub-555?style=for-the-badge&logo=github&logoColor=white)](https://github.com/cactus-compute/cactus)[![HuggingFace](https://img.shields.io/badge/HuggingFace-555?style=for-the-badge&logo=huggingface&logoColor=white)](https://huggingface.co/Cactus-Compute)[![Reddit](https://img.shields.io/badge/Reddit-555?style=for-the-badge&logo=reddit&logoColor=white)](https://www.reddit.com/r/cactuscompute/)[![Blog](https://img.shields.io/badge/Blog-555?style=for-the-badge&logo=hashnode&logoColor=white)](https://cactus-compute.github.io/cactus/blog/)

A low-latency AI engine for mobile devices & wearables. Main features:

- **Fast:** fastest inference on ARM CPU
- **Low RAM:** zero-copy memory mapping ensures 10x lower RAM use than other engines
- **Multimodal:** one SDK for speech, vision, and language models
- **Cloud fallback:** automatically route requests to cloud models if needed
- **Energy-efficient:** NPU-accelerated prefill

```
┌─────────────────┐
│  Cactus Engine  │ ←── OpenAI-compatible APIs for all major languages
└─────────────────┘     Chat, vision, STT, RAG, tool call, cloud handoff
         │
┌─────────────────┐
│  Cactus Graph   │ ←── Zero-copy computation graph (PyTorch for mobile)
└─────────────────┘     Custom models, optimised for RAM & quantisation
         │
┌─────────────────┐
│ Cactus Kernels  │ ←── ARM SIMD kernels (Apple, Snapdragon, Exynos, etc)
└─────────────────┘     Custom attention, KV-cache quant, chunked prefill
```

## Quick Demo (Mac)

- Step 1: `brew install cactus-compute/cactus/cactus`
- Step 2: `cactus transcribe` or `cactus run`

## Cactus Engine

```cpp
#include "cactus.h"

cactus_model_t model = cactus_init(
    "path/to/weight/folder",
    "path to txt or dir of txts for auto-rag",
    false
);

const char* messages = R"([\
    {"role": "system", "content": "You are a helpful assistant."},\
    {"role": "user", "content": "My name is Henry Ndubuaku"}\
])";

const char* options = R"({
    "max_tokens": 50,
    "stop_sequences": ["<|im_end|>"]
})";

char response[4096];
int result = cactus_complete(
    model,            // model handle
    messages,         // JSON chat messages
    response,         // response buffer
    sizeof(response), // buffer size
    options,          // generation options
    nullptr,          // tools JSON
    nullptr,          // streaming callback
    nullptr           // user data
);
```

Example response from Gemma3-270m

```json
{
    "success": true,        // generation succeeded
    "error": null,          // error details if failed
    "cloud_handoff": false, // true if cloud model used
    "response": "Hi there!",
    "function_calls": [],   // parsed tool calls
    "confidence": 0.8193,   // model confidence
    "time_to_first_token_ms": 45.23,
    "total_time_ms": 163.67,
    "prefill_tps": 1621.89,
    "decode_tps": 168.42,
    "ram_usage_mb": 245.67,
    "prefill_tokens": 28,
    "decode_tokens": 50,
    "total_tokens": 78
}
```

## Cactus Graph

```cpp
#include "cactus.h"

CactusGraph graph;
auto a = graph.input({2, 3}, Precision::FP16);
auto b = graph.input({3, 4}, Precision::INT8);

auto x1 = graph.matmul(a, b, false);
auto x2 = graph.transpose(x1);
auto result = graph.matmul(b, x2, true);

float a_data[6] = {1.1f, 2.3f, 3.4f, 4.2f, 5.7f, 6.8f};
float b_data[12] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};

graph.set_input(a, a_data, Precision::FP16);
graph.set_input(b, b_data, Precision::INT8);

graph.execute();
void* output_data = graph.get_output(result);

graph.hard_reset();
```

## API & SDK References

| Reference | Language | Description |
| --- | --- | --- |
| [Engine API](https://huggingface.co/spaces/Cactus-Compute/README/blob/main/docs/cactus_engine.md) | C | Chat completion, streaming, tool calling, transcription, embeddings, RAG, vision, VAD, vector index, cloud handoff |
| [Graph API](https://huggingface.co/spaces/Cactus-Compute/README/blob/main/docs/cactus_graph.md) | C++ | Tensor operations, matrix multiplication, attention, normalization, activation functions |
| [Python SDK](https://huggingface.co/python/) | Python | Mac, Linux |
| [Swift SDK](https://huggingface.co/apple/) | Swift | iOS, macOS, tvOS, watchOS, Android |
| [Kotlin SDK](https://huggingface.co/android/) | Kotlin | Android, iOS (via KMP) |
| [Flutter SDK](https://huggingface.co/flutter/) | Dart | iOS, macOS, Android |
| [Rust SDK](https://huggingface.co/rust/) | Rust | Mac, Linux |
| [React Native](https://github.com/cactus-compute/cactus-react-native) | JavaScript | iOS, Android |

> **Model weights:** Pre-converted weights for all supported models at [huggingface.co/Cactus-Compute](https://huggingface.co/Cactus-Compute).

## Benchmarks (CPU-only, no GPU)

- All weights INT4 quantised
- LFM: 1k-prefill / 100-decode, values are prefill tps / decode tps
- LFM-VL: 256px input, values are latency / decode tps
- Parakeet: 20s audio input, values are latency / decode tps
- Missing latency = no NPU support yet

| Device | LFM 1.2B | LFMVL 1.6B | Parakeet 1.1B | VL RAM Usage |
| --- | --- | --- | --- | --- |
| Mac M4 Pro | 582/100 | 0.2s/98 | 0.1s/900k+ | 76MB |
| iPad/Mac M3 | 350/60 | 0.3s/69 | 0.3s/800k+ | 70MB |
| iPhone 17 Pro | 327/48 | 0.3s/48 | 0.3s/300k+ | 108MB |
| iPhone 13 Mini | 148/34 | 0.3s/35 | 0.7s/90k+ | 1GB |
| Galaxy S25 Ultra | 255/37 | -/34 | -/250k+ | 1.5GB |
| Pixel 6a | 70/15 | -/15 | -/17k+ | 1GB |
| Galaxy A17 5G | 32/10 | -/11 | -/40k+ | 727MB |
| CMF Phone 2 Pro | - | - | - | - |
| Raspberry Pi 5 | 69/11 | 13.3s/11 | 4.5s/180k+ | 869MB |

## Supported Transcription Model

- STT: 20s audio input on Macbook Air M3 chip
- Benchmark dataset: internal evals with production users

| Model | Params | End2End ms | Latency ms | Decode toks/sec | NPU | RTF | WER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| UsefulSensors/moonshine-base | 61M | 361 | 182 | 262 | yes | 0.0180 | 0.1395 |
| openai/whisper-tiny | 39M | 232 | 137 | 581 | yes | 0.0116 | 0.1860 |
| openai/whisper-base | 74M | 329 | 178 | 358 | yes | 0.0164 | 0.1628 |
| openai/whisper-small | 244M | 856 | 332 | 108 | yes | 0.0428 | 0.0930 |
| openai/whisper-medium | 769M | 2085 | 923 | 49 | yes | 0.1041 | 0.0930 |
| nvidia/parakeet-ctc-0.6b | 600M | 201 | 201 | 5214285 | yes | 0.0101 | 0.0930 |
| nvidia/parakeet-tdt-0.6b-v3 | 600M | 718 | 718 | 3583333 | yes | 0.0359 | 0.0465 |
| nvidia/parakeet-ctc-1.1b | 1.1B | 279 | 278 | 4562500 | yes | 0.0139 | 0.1628 |
| snakers4/silero-vad | - | - | - | - | - | - | - |

## Supported LLMs

- Gemma weights are often **gated** on HuggingFace, needs tokens
- Run `huggingface-cli login` and input your huggingface token

| Model | Features |
| --- | --- |
| google/gemma-3-270m-it | completion |
| google/functiongemma-270m-it | tools |
| google/gemma-3-1b-it | completion, gated |
| google/gemma-3n-E2B-it | completion, tools |
| google/gemma-3n-E4B-it | completion, tools |
| Qwen/Qwen3-0.6B | completion, tools, embed |
| Qwen/Qwen3-Embedding-0.6B | embed |
| Qwen/Qwen3.5-0.8B | vision, completion, tools, embed |
| Qwen/Qwen3-1.7B | completion, tools, embed |
| Qwen/Qwen3.5-2B | vision, completion, tools, embed |
| LiquidAI/LFM2-350M | completion, tools, embed |
| LiquidAI/LFM2-700M | completion, tools, embed |
| LiquidAI/LFM2-8B-A1B | completion, tools, embed |
| LiquidAI/LFM2.5-1.2B-Thinking | completion, tools, embed |
| LiquidAI/LFM2.5-1.2B-Instruct | completion, tools, embed |
| LiquidAI/LFM2-2.6B | completion, tools, embed |
| LiquidAI/LFM2-VL-450M | vision, txt & img embed, Apple NPU |
| LiquidAI/LFM2.5-VL-1.6B | vision, txt & img embed, Apple NPU |
| tencent/Youtu-LLM-2B | completion, tools, embed |
| nomic-ai/nomic-embed-text-v2-moe | embed |

## Roadmap

| Date | Status | Milestone |
| --- | --- | --- |
| Sep 2025 | Done | Released v1 |
| Oct 2025 | Done | Chunked prefill, KVCache Quant (2x prefill) |
| Nov 2025 | Done | Cactus Attention (10 & 1k prefill = same decode) |
| Dec 2025 | Done | Team grows to +6 Research Engineers |
| Jan 2026 | Done | Apple NPU/RAM, 5-11x faster iOS/Mac |
| Feb 2026 | Done | Hybrid inference, INT4, lossless Quant (1.5x) |
| Mar 2026 | Coming | Qualcomm/Google NPUs, 5-11x faster Android |
| Apr 2026 | Coming | Mediatek/Exynos NPUs, Cactus@ICLR |
| May 2026 | Coming | Wearables & custom chips optimisations |
| Jun 2026 | Coming | Torch/JAX model transpilers |

## Using this repo

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│ Step 0: if on Linux (Ubuntu/Debian)                                          │
│ sudo apt-get install python3 python3-venv python3-pip cmake                  │
│   build-essential libcurl4-openssl-dev                                       │
│                                                                              │
│ Step 1: clone and setup                                                      │
│ git clone https://github.com/cactus-compute/cactus && cd cactus              │
│ source ./setup                                                               │
│                                                                              │
│ Step 2: use the commands                                                     │
│──────────────────────────────────────────────────────────────────────────────│
│                                                                              │
│  cactus auth                         manage Cloud API key                    │
│    --status                          show key status                         │
│    --clear                           remove saved key                        │
│                                                                              │
│  cactus run <model>                  opens playground (auto downloads)       │
│    --precision INT4|INT8|FP16        quantization (default: INT4)            │
│    --token <token>                   HF token (gated models)                 │
│    --reconvert                       force reconversion from source          │
│                                                                              │
│  cactus transcribe [model]           live mic transcription (parakeet-1.1b)  │
│    --file <audio.wav>                transcribe file instead of mic          │
│    --precision INT4|INT8|FP16        quantization (default: INT4)            │
│    --token <token>                   HF token (gated models)                 │
│    --reconvert                       force reconversion from source          │
│                                                                              │
│  cactus download <model>             downloads model to ./weights            │
│    --precision INT4|INT8|FP16        quantization (default: INT4)            │
│    --token <token>                   HuggingFace API token                   │
│    --reconvert                       force reconversion from source          │
│                                                                              │
│  cactus convert <model> [dir]        convert model, supports LoRA merge      │
│    --precision INT4|INT8|FP16        quantization (default: INT4)            │
│    --lora <path>                     LoRA adapter to merge                   │
│    --token <token>                   HuggingFace API token                   │
│                                                                              │
│  cactus build                        build for ARM → build/libcactus.a       │
│    --apple                           Apple (iOS/macOS)                       │
│    --android                         Android                                 │
│    --flutter                         Flutter (all platforms)                 │
│    --python                          shared lib for Python FFI               │
│                                                                              │
│  cactus test                         run unit tests and benchmarks           │
│    --model <model>                   default: LFM2-VL-450M                   │
│    --transcribe_model <model>        default: moonshine-base                 │
│    --benchmark                       use larger models                       │
│    --precision INT4|INT8|FP16        regenerate weights with precision       │
│    --reconvert                       force reconversion from source          │
│    --no-rebuild                      skip building library                   │
│    --llm / --stt / --performance     run specific test suite                 │
│    --ios                             run on connected iPhone                 │
│    --android                         run on connected Android                │
│                                                                              │
│  cactus clean                        remove all build artifacts              │
│  cactus --help                       show all commands and flags             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Maintaining Organisations

01. [Cactus Compute, Inc. (YC S25)](https://cactuscompute.com/)
02. [UCLA's BruinAI](https://bruinai.org/)
03. [Char (YC S25)](https://char.com/)
04. [Yale's AI Society](https://www.yale-ai.org/team)
05. [National University of Singapore's AI Society](https://www.nusaisociety.org/)
06. [UC Irvine's AI@UCI](https://aiclub.ics.uci.edu/)
07. [Imperial College's AI Society](https://www.imperialcollegeunion.org/csp/1391)
08. [University of Pennsylvania's AI@Penn](https://ai-at-penn-main-105.vercel.app/)
09. [University of Michigan Ann-Arbor MSAIL](https://msail.github.io/)
10. [University of Colorado Boulder's AI Club](https://www.cuaiclub.org/)

## Citation

If you use Cactus in your research, please cite it as follows:

```bibtex
@software{cactus,
  title        = {Cactus: AI Inference Engine for Phones & Wearables},
  author       = {Ndubuaku, Henry and Cactus Team},
  url          = {https://github.com/cactus-compute/cactus},
  year         = {2025}
}
```

**N/B:** Scroll all the way up and click the shields link for resources!

### [Collections4](https://huggingface.co/Cactus-Compute/collections "Go to Cactus-Compute's collections page")

[Language Models](https://huggingface.co/collections/Cactus-Compute/language-models)

- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/Qwen3-0.6B**\\
\\
Text Generation •Updated 25 days ago• 160• 1](https://huggingface.co/Cactus-Compute/Qwen3-0.6B)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/Qwen3-1.7B**\\
\\
Text Generation •Updated 25 days ago• 175• 1](https://huggingface.co/Cactus-Compute/Qwen3-1.7B)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/Qwen3.5-0.8B**\\
\\
Image-Text-to-Text •Updated 25 days ago• 19• 1](https://huggingface.co/Cactus-Compute/Qwen3.5-0.8B)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/Qwen3.5-2B**\\
\\
Image-Text-to-Text •Updated 25 days ago• 15• 1](https://huggingface.co/Cactus-Compute/Qwen3.5-2B)

[Speech-to-Text Models](https://huggingface.co/collections/Cactus-Compute/speech-to-text-models)

- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-tiny**\\
\\
Automatic Speech Recognition •Updated 25 days ago• 28• 1](https://huggingface.co/Cactus-Compute/whisper-tiny)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-base**\\
\\
Automatic Speech Recognition •Updated 25 days ago• 23• 1](https://huggingface.co/Cactus-Compute/whisper-base)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-small**\\
\\
Automatic Speech Recognition •Updated 25 days ago• 25• 1](https://huggingface.co/Cactus-Compute/whisper-small)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-medium**\\
\\
Automatic Speech Recognition •Updated 25 days ago• 28• 1](https://huggingface.co/Cactus-Compute/whisper-medium)

[Language Models](https://huggingface.co/collections/Cactus-Compute/language-models)

- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/Qwen3-0.6B**\\
\\
Text Generation •Updated 25 days ago• 160• 1](https://huggingface.co/Cactus-Compute/Qwen3-0.6B)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/Qwen3-1.7B**\\
\\
Text Generation •Updated 25 days ago• 175• 1](https://huggingface.co/Cactus-Compute/Qwen3-1.7B)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/Qwen3.5-0.8B**\\
\\
Image-Text-to-Text •Updated 25 days ago• 19• 1](https://huggingface.co/Cactus-Compute/Qwen3.5-0.8B)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/Qwen3.5-2B**\\
\\
Image-Text-to-Text •Updated 25 days ago• 15• 1](https://huggingface.co/Cactus-Compute/Qwen3.5-2B)

[Speech-to-Text Models](https://huggingface.co/collections/Cactus-Compute/speech-to-text-models)

- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-tiny**\\
\\
Automatic Speech Recognition •Updated 25 days ago• 28• 1](https://huggingface.co/Cactus-Compute/whisper-tiny)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-base**\\
\\
Automatic Speech Recognition •Updated 25 days ago• 23• 1](https://huggingface.co/Cactus-Compute/whisper-base)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-small**\\
\\
Automatic Speech Recognition •Updated 25 days ago• 25• 1](https://huggingface.co/Cactus-Compute/whisper-small)
- [![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-medium**\\
\\
Automatic Speech Recognition •Updated 25 days ago• 28• 1](https://huggingface.co/Cactus-Compute/whisper-medium)

[View 4 collections](https://huggingface.co/Cactus-Compute/collections)

### [models53](https://huggingface.co/Cactus-Compute/models "Go to Cactus-Compute's models page")    Sort:  Recently updated

[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/needle**\\
\\
Updated about 11 hours ago• 31](https://huggingface.co/Cactus-Compute/needle)[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/parakeet-ctc-0.6b-cq**\\
\\
Updated 1 day ago](https://huggingface.co/Cactus-Compute/parakeet-ctc-0.6b-cq)[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/parakeet-tdt-0.6b-v3-cq**\\
\\
Updated 1 day ago](https://huggingface.co/Cactus-Compute/parakeet-tdt-0.6b-v3-cq)[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-tiny-cq**\\
\\
Updated 1 day ago](https://huggingface.co/Cactus-Compute/whisper-tiny-cq)[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-medium-cq**\\
\\
Updated 1 day ago](https://huggingface.co/Cactus-Compute/whisper-medium-cq)[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/whisper-large-v3-cq**\\
\\
Updated 1 day ago](https://huggingface.co/Cactus-Compute/whisper-large-v3-cq)[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/Qwen3-0.6B-cq**\\
\\
Updated 1 day ago](https://huggingface.co/Cactus-Compute/Qwen3-0.6B-cq)[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/LFM2.5-VL-1.6B-cq**\\
\\
Updated 1 day ago](https://huggingface.co/Cactus-Compute/LFM2.5-VL-1.6B-cq)[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/LFM2.5-VL-450M-cq**\\
\\
Updated 1 day ago](https://huggingface.co/Cactus-Compute/LFM2.5-VL-450M-cq)[![](https://cdn-avatars.huggingface.co/v1/production/uploads/68519cc25c4f4e5e8099a501/pRCfURUZpZj8NqCxCVdv1.jpeg)\\
\\
**Cactus-Compute/gemma-4-e2b-it-cq**\\
\\
Updated 2 days ago](https://huggingface.co/Cactus-Compute/gemma-4-e2b-it-cq)

[View 53\\
models](https://huggingface.co/Cactus-Compute/models)

### [datasets3](https://huggingface.co/Cactus-Compute/datasets "Go to Cactus-Compute's datasets page")    Sort:  Recently updated

[**Cactus-Compute/gemma-4-e2b-it-cq**\\
\\
Updated 5 days ago• 27](https://huggingface.co/datasets/Cactus-Compute/gemma-4-e2b-it-cq)[**Cactus-Compute/gemma4-tflite-encoders**\\
\\
Updated 9 days ago• 12](https://huggingface.co/datasets/Cactus-Compute/gemma4-tflite-encoders)[**Cactus-Compute/needle-tokenizer**\\
\\
Updated Apr 1• 172](https://huggingface.co/datasets/Cactus-Compute/needle-tokenizer)

System theme

Company

[TOS](https://huggingface.co/terms-of-service) [Privacy](https://huggingface.co/privacy) [About](https://huggingface.co/huggingface) [Careers](https://apply.workable.com/huggingface/)  [Hugging Face](https://huggingface.co/)

Website

[Models](https://huggingface.co/models) [Datasets](https://huggingface.co/datasets) [Spaces](https://huggingface.co/spaces) [Pricing](https://huggingface.co/pricing) [Docs](https://huggingface.co/docs)

StripeM-Inner