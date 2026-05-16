[Skip to content](https://docs.cactuscompute.com/latest/blog/turboquant-h/#turboquant-h-hadamard-rotation-for-2-bit-embedding-quantization)


You're not viewing the latest version.
[**Click here to go to latest.**](https://docs.cactuscompute.com/)

[![logo](https://docs.cactuscompute.com/latest/assets/logo_white.png)](https://docs.cactuscompute.com/latest/ "Cactus Docs")

Cactus Docs


v1.14

- [v1.14](https://docs.cactuscompute.com/v1.14/)
- [v1.13](https://docs.cactuscompute.com/v1.13/)
- [v1.12](https://docs.cactuscompute.com/v1.12/)
- [v1.11](https://docs.cactuscompute.com/v1.11/)
- [v1.10](https://docs.cactuscompute.com/v1.10/)
- [v1.9](https://docs.cactuscompute.com/v1.9/)
- [v1.8](https://docs.cactuscompute.com/v1.8/)
- [v1.7](https://docs.cactuscompute.com/v1.7/)


TurboQuant-H: Hadamard Rotation for 2-Bit Embedding Quantization



Type to start searching

[cactus-compute/cactus\\
\\
\\
- v1.14\\
- 4.9k\\
- 383](https://github.com/cactus-compute/cactus "Go to repository")

- [Home](https://docs.cactuscompute.com/latest/)
- [Quickstart](https://docs.cactuscompute.com/latest/docs/quickstart/)
- [Choose Your SDK](https://docs.cactuscompute.com/latest/docs/choose-sdk/)
- [SDKs](https://docs.cactuscompute.com/latest/react-native/)
- [Core APIs (C++)](https://docs.cactuscompute.com/latest/docs/cactus_engine/)
- [Guides](https://docs.cactuscompute.com/latest/docs/finetuning/)
- [Contributing](https://docs.cactuscompute.com/latest/CONTRIBUTING/)
- [Blog](https://docs.cactuscompute.com/latest/blog/)

[![logo](https://docs.cactuscompute.com/latest/assets/logo_white.png)](https://docs.cactuscompute.com/latest/ "Cactus Docs")
Cactus Docs


[cactus-compute/cactus\\
\\
\\
- v1.14\\
- 4.9k\\
- 383](https://github.com/cactus-compute/cactus "Go to repository")

- [Home](https://docs.cactuscompute.com/latest/)
- [Quickstart](https://docs.cactuscompute.com/latest/docs/quickstart/)
- [Choose Your SDK](https://docs.cactuscompute.com/latest/docs/choose-sdk/)
- [ ]


SDKs






SDKs




  - [React Native](https://docs.cactuscompute.com/latest/react-native/)
  - [Python](https://docs.cactuscompute.com/latest/python/)
  - [Swift](https://docs.cactuscompute.com/latest/apple/)
  - [Kotlin / Android](https://docs.cactuscompute.com/latest/android/)
  - [Flutter](https://docs.cactuscompute.com/latest/flutter/)
  - [Rust](https://docs.cactuscompute.com/latest/rust/)

- [ ]


Core APIs (C++)






Core APIs (C++)




  - [Engine API](https://docs.cactuscompute.com/latest/docs/cactus_engine/)
  - [Graph API](https://docs.cactuscompute.com/latest/docs/cactus_graph/)
  - [Index API](https://docs.cactuscompute.com/latest/docs/cactus_index/)

- [ ]


Guides






Guides




  - [Fine-tuning & Deployment](https://docs.cactuscompute.com/latest/docs/finetuning/)
  - [Runtime Compatibility](https://docs.cactuscompute.com/latest/docs/compatibility/)

- [Contributing](https://docs.cactuscompute.com/latest/CONTRIBUTING/)
- [x]


Blog






Blog




  - [All Posts](https://docs.cactuscompute.com/latest/blog/)
  - [ ]


     TurboQuant-H



     [TurboQuant-H](https://docs.cactuscompute.com/latest/blog/turboquant-h/)
     Table of contents


    - [Abstract](https://docs.cactuscompute.com/latest/blog/turboquant-h/#abstract)
    - [1\. Introduction](https://docs.cactuscompute.com/latest/blog/turboquant-h/#1-introduction)
    - [2\. Background: Per-Layer Embeddings Dominate Model Storage](https://docs.cactuscompute.com/latest/blog/turboquant-h/#2-background-per-layer-embeddings-dominate-model-storage)
    - [3\. TurboQuant-H](https://docs.cactuscompute.com/latest/blog/turboquant-h/#3-turboquant-h)

      - [3.1 Comparison with TurboQuant](https://docs.cactuscompute.com/latest/blog/turboquant-h/#31-comparison-with-turboquant)
      - [3.2 Formal Description](https://docs.cactuscompute.com/latest/blog/turboquant-h/#32-formal-description)
      - [3.3 The Quantization Pipeline](https://docs.cactuscompute.com/latest/blog/turboquant-h/#33-the-quantization-pipeline)
      - [3.4 Design Decisions](https://docs.cactuscompute.com/latest/blog/turboquant-h/#34-design-decisions)

    - [4\. Results](https://docs.cactuscompute.com/latest/blog/turboquant-h/#4-results)

      - [4.1 Perplexity](https://docs.cactuscompute.com/latest/blog/turboquant-h/#41-perplexity)
      - [4.2 Disk Footprint](https://docs.cactuscompute.com/latest/blog/turboquant-h/#42-disk-footprint)

    - [5\. Inference Path](https://docs.cactuscompute.com/latest/blog/turboquant-h/#5-inference-path)

      - [5.1 Before (Cactus default)](https://docs.cactuscompute.com/latest/blog/turboquant-h/#51-before-cactus-default)
      - [5.2 After (Cactus TurboQuant-H)](https://docs.cactuscompute.com/latest/blog/turboquant-h/#52-after-cactus-turboquant-h)
      - [5.3 Overhead Analysis](https://docs.cactuscompute.com/latest/blog/turboquant-h/#53-overhead-analysis)

    - [6\. Related Work](https://docs.cactuscompute.com/latest/blog/turboquant-h/#6-related-work)
    - [7\. Next Steps](https://docs.cactuscompute.com/latest/blog/turboquant-h/#7-next-steps)
    - [Try It](https://docs.cactuscompute.com/latest/blog/turboquant-h/#try-it)
    - [Citation](https://docs.cactuscompute.com/latest/blog/turboquant-h/#citation)
    - [References](https://docs.cactuscompute.com/latest/blog/turboquant-h/#references)
    - [See Also](https://docs.cactuscompute.com/latest/blog/turboquant-h/#see-also)

  - [Gemma 4 on Cactus](https://docs.cactuscompute.com/latest/blog/gemma4/)
  - [Hybrid Transcription](https://docs.cactuscompute.com/latest/blog/hybrid_transcription/)
  - [LFM2-24B on Mac](https://docs.cactuscompute.com/latest/blog/lfm2_24b_a2b/)
  - [Parakeet CTC 1.1B](https://docs.cactuscompute.com/latest/blog/parakeet/)
  - [LFM-2.5-350m](https://docs.cactuscompute.com/latest/blog/lfm2.5_350m/)

Table of contents


- [Abstract](https://docs.cactuscompute.com/latest/blog/turboquant-h/#abstract)
- [1\. Introduction](https://docs.cactuscompute.com/latest/blog/turboquant-h/#1-introduction)
- [2\. Background: Per-Layer Embeddings Dominate Model Storage](https://docs.cactuscompute.com/latest/blog/turboquant-h/#2-background-per-layer-embeddings-dominate-model-storage)
- [3\. TurboQuant-H](https://docs.cactuscompute.com/latest/blog/turboquant-h/#3-turboquant-h)

  - [3.1 Comparison with TurboQuant](https://docs.cactuscompute.com/latest/blog/turboquant-h/#31-comparison-with-turboquant)
  - [3.2 Formal Description](https://docs.cactuscompute.com/latest/blog/turboquant-h/#32-formal-description)
  - [3.3 The Quantization Pipeline](https://docs.cactuscompute.com/latest/blog/turboquant-h/#33-the-quantization-pipeline)
  - [3.4 Design Decisions](https://docs.cactuscompute.com/latest/blog/turboquant-h/#34-design-decisions)

- [4\. Results](https://docs.cactuscompute.com/latest/blog/turboquant-h/#4-results)

  - [4.1 Perplexity](https://docs.cactuscompute.com/latest/blog/turboquant-h/#41-perplexity)
  - [4.2 Disk Footprint](https://docs.cactuscompute.com/latest/blog/turboquant-h/#42-disk-footprint)

- [5\. Inference Path](https://docs.cactuscompute.com/latest/blog/turboquant-h/#5-inference-path)

  - [5.1 Before (Cactus default)](https://docs.cactuscompute.com/latest/blog/turboquant-h/#51-before-cactus-default)
  - [5.2 After (Cactus TurboQuant-H)](https://docs.cactuscompute.com/latest/blog/turboquant-h/#52-after-cactus-turboquant-h)
  - [5.3 Overhead Analysis](https://docs.cactuscompute.com/latest/blog/turboquant-h/#53-overhead-analysis)

- [6\. Related Work](https://docs.cactuscompute.com/latest/blog/turboquant-h/#6-related-work)
- [7\. Next Steps](https://docs.cactuscompute.com/latest/blog/turboquant-h/#7-next-steps)
- [Try It](https://docs.cactuscompute.com/latest/blog/turboquant-h/#try-it)
- [Citation](https://docs.cactuscompute.com/latest/blog/turboquant-h/#citation)
- [References](https://docs.cactuscompute.com/latest/blog/turboquant-h/#references)
- [See Also](https://docs.cactuscompute.com/latest/blog/turboquant-h/#see-also)

# TurboQuant-H: Hadamard Rotation for 2-Bit Embedding Quantization [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#turboquant-h-hadamard-rotation-for-2-bit-embedding-quantization "Permanent link")

_By Karen Mosoyan & Henry Ndubuaku_

_(karen@cactuscompute.com, henry@cactuscompute.com)_

## Abstract [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#abstract "Permanent link")

TurboQuant (Zandieh et al., ICLR 2026) compresses KV cache vectors to 1-3 bits via random orthogonal rotation, optimal scalar quantization, and QJL bias correction. We introduce **TurboQuant-H**, a simplified offline variant that replaces random rotation with Hadamard rotation, uses per-group Lloyd-Max codebooks, and drops the QJL correction stage. We apply TurboQuant-H to per-layer input (PLI) embedding tables in Gemma 4 E2B, where embeddings constitute 60.6% of total model weight. On Gemma 4 E2B, TurboQuant-H compresses PLI weights from 2,496 MB to 624 MB (4x) at 2.125 effective bits per dimension, reducing total LLM storage by 40% (4,790 MB → 2,918 MB) with a perplexity increase of 0.06 (1.85 → 1.91) and no measured speed regression.

## 1\. Introduction [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#1-introduction "Permanent link")

TurboQuant (ICLR 2026) compresses KV cache vectors to 1-3 bits with near-zero quality loss. The technique is elegant: rotate vectors with a random orthogonal matrix, exploit the resulting Beta distribution to apply optimal scalar quantizers per coordinate, then correct inner product bias with a 1-bit QJL residual. The paper demonstrates quality neutrality at 3.5 bits and marginal degradation at 2.5 bits on Llama-3.1-8B and Ministral-7B.

But TurboQuant was designed for KV cache, vectors generated at runtime during inference. There's a catch: mobile devices and wearables need small models, which we found to significantly degrade when KV cache goes below INT4. We in fact keep KV cache at INT8 on Cactus to ensure correctness. This makes applying TurboQuant to Cactus KV workloads tricky.

However, with the emergence of per-layer embedding architectures (each layer has its own embedding lookup), these embeddings dominate the parameter count of models like the Gemma E-series. For instance, Gemma E2B has 2.3B effective parameters but 5.1B total, because the per-layer embeddings alone account for the difference. That bloats memory and storage footprint by more than 2x. There is a need to re-visit embedding quantisation.

## 2\. Background: Per-Layer Embeddings Dominate Model Storage [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#2-background-per-layer-embeddings-dominate-model-storage "Permanent link")

Most quantization research focuses on linear layer weights and activations. Embeddings are treated as untouchable lookup tables, typically kept at FP16 or at best INT8 while everything else goes to INT4. This made sense when embeddings were a small fraction of total parameters. That assumption broke with per-layer embedding architectures.

Gemma 4 E2B uses AltUp, a technique where each of the 35 transformer layers gets its own embedding projection from the 262K-token vocabulary. Instead of one shared embedding table, you have a shared table plus a per-layer table. The numbers on Cactus's current INT4 weights:

| Component | Size | % of Model |
| --- | --- | --- |
| `token_embeddings` (shared) | 408 MB | 8.7% |
| `embed_tokens_per_layer` (35 layers) | 2,496 MB | 52.1% |
| **Total embedding storage** | **2,904 MB** | **60.6%** |
| All other weights (attention, FFN, norms, encoders) | 1,886 MB | 39.4% |
| **Total model** | **4,790 MB** | 100% |

The per-layer embedding table is 2.5 GB. More than half the model. This is not unique to Gemma 4. The AltUp design pattern, where per-layer vocabulary projections replace a single shared embedding, is becoming standard for models that need large vocabularies (262K tokens for multilingual coverage) without proportionally large hidden dimensions. Gemma 3n uses the same architecture. Any model that follows this pattern will be embedding-dominated.

## 3\. TurboQuant-H [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#3-turboquant-h "Permanent link")

TurboQuant-H shares the core insight from TurboQuant; rotation concentrates coordinates into a well-behaved distribution, enabling aggressive scalar quantization, but simplifies the pipeline for offline weight quantization.

### 3.1 Comparison with TurboQuant [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#31-comparison-with-turboquant "Permanent link")

|  | TurboQuant (Zandieh et al.) | TurboQuant-H (this work) |
| --- | --- | --- |
| **Target** | KV cache (runtime activations) | Embedding weight tables (offline) |
| **Rotation** | Random orthogonal matrix via QR of Gaussian, O(d2) | Normalized Hadamard matrix, O(Nlog⁡N), symmetric = self-inverse |
| **Quantizer** | Per-coordinate scalar quantizer (precomputed for Beta distribution) | Per-position Lloyd-Max codebook (trained on actual weight distribution) |
| **Codebook** | Implicit (quantization levels derived from Beta CDF) | Explicit FP16 centroids per position group (0.125 bits overhead at group-128) |
| **Bias correction** | Two-stage: MSE quantizer at b−1 bits + 1-bit QJL residual | Single-stage: no QJL correction |
| **When it runs** | Every forward pass during inference | Once during weight conversion |
| **Bit width** | 2.5-bit and 3.5-bit | 2-bit (+0.125 codebook overhead ≈ 2.125 effective) |

### 3.2 Formal Description [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#32-formal-description "Permanent link")

Let E∈RV×D be the PLI embedding matrix with vocabulary size V=262,144 and embedding dimension D=8,190. We partition each row into P=⌈D/G⌉=64 positional groups of G=128 contiguous elements. The p-th positional group of vocabulary row v is denoted xv,p∈RG.

**Quantization** (offline, during weight conversion):

**Step 1: Hadamard rotation.** For each row v and position p, rotate:

x^v,p=H¯G⋅xv,p

where H¯G=1GHG is the G×G normalized Hadamard matrix, satisfying H¯GTH¯G=I and H¯G=H¯GT. The 1G normalization ensures the transform is its own inverse.

**Step 2: Codebook training.** For each positional group p∈{1,…,P}, collect the rotated values from all V vocabulary rows and train a Lloyd-Max codebook Cp={c1,c2,c3,c4} (at b=2 bits, 4 centroids) by minimizing:

Cp∗=arg⁡minC∑v=1V∑i=1Gminc∈C(x^v,p,i−c)2

This trains each codebook on V×G=262,144×128≈33.6M data points, giving the Lloyd-Max algorithm sufficient statistics for accurate centroid placement. Each positional group gets its own codebook because the weight distributions vary across positions in the embedding dimension. We tried a single joint codebook shared across all positions; per-position was consistently better.

The codebook values are stored at FP16 (16 bits per centroid), contributing:

2b⋅16G=4⋅16128=0.125 bits/element overhead

**Step 3: Quantize by proximity.** Each rotated element maps to its nearest centroid:

qv,p,i=arg⁡minj∈{1,…,2b}\|x^v,p,i−cj\|

Store the 2-bit indices qv,p,i and the P=64 FP16 codebooks {C1,…,CP}.

**Dequantization** (at inference):

x~v,p=H¯G⋅scatter(Cp,qv,p)

where scatter(Cp,qv,p)i=cqv,p,i maps indices back to centroids. Since H¯G is symmetric and orthogonal, the inverse rotation is the same forward transform. No transpose is needed.

**Effective bit rate:**

beff=b+2b⋅16G=2+0.125=2.125 bits/element

### 3.3 The Quantization Pipeline [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#33-the-quantization-pipeline "Permanent link")

```
QUANTIZATION (offline, during cactus convert)
==============================================

PLI Matrix E  (262K x 8190)
      |
      v
+-----------------------+
| Partition into        |  Each row -> 64 positional groups
| groups of G=128       |  of 128 contiguous elements
+-----------+-----------+
            |
            v
+-----------------------+
| Hadamard rotation     |  x_hat = (1/sqrt(G)) * H_128 * x
| per group             |  O(G log G) butterfly
+-----------+-----------+
            |
            v
+-----------------------+
| Lloyd-Max codebook    |  Train 4 centroids (2-bit) per position
| per position          |  across all 262K vocab rows
|                       |  C_p = {c1, c2, c3, c4} in FP16
+-----------+-----------+
            |
            v
+-----------------------+
| Quantize by           |  q = argmin_j |x_hat_i - c_j|
| proximity             |  Store 2-bit indices per element
+-----------+-----------+
            |
            v
Output: 2-bit index tensor + 64 FP16 codebooks
Effective: 2.125 bits/element

DEQUANTIZATION (at inference, per token)
=========================================

Token IDs
      |
      v
+-----------------------+
| Gather 2-bit indices  |  Look up row from compressed table
| + codebook per pos.   |  ~3.8x less bandwidth than INT8
+-----------+-----------+
            |
            v
+-----------------------+
| Scatter codebook      |  Replace 2-bit indices with FP16
| values                |  centroid values from C_p
+-----------+-----------+
            |
            v
+-----------------------+
| Hadamard rotation     |  x_tilde = (1/sqrt(G)) * H_128 * scatter(...)
| (same as forward,     |  H_bar is symmetric: H_bar = H_bar^T = H_bar^-1
|  no transpose needed) |  O(G log G) butterfly per group
+-----------+-----------+
            |
            v
FP16 embedding -> feed to transformer layer
```

### 3.4 Design Decisions [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#34-design-decisions "Permanent link")

**Why Hadamard instead of random orthogonal?** The normalized Hadamard matrix H¯G=1GHG is deterministic, O(Nlog⁡N) to apply via the butterfly factorization (same structure as the FFT), and its own inverse (H¯=H¯T=H¯−1). For offline weight quantization we don't need the data-oblivious guarantees of a random rotation, we have full access to the weight data at conversion time. The Hadamard rotation still concentrates coordinates, which is all we need to make low-bit scalar quantization work. Note: the unnormalized Hadamard satisfies HHT=G⋅I, so the 1G factor is essential for the self-inverse property.

**Why no QJL correction?** TurboQuant's second stage exists because MSE-optimal quantizers introduce multiplicative bias in inner product estimation. At 1-bit, E\[⟨y,Q(x)⟩\]=2π⟨y,x⟩, a 36% shrinkage. The QJL residual corrects this at the cost of 1 additional bit per dimension. But we're quantizing at 2 bits with a trained codebook, not a precomputed scalar quantizer. The per-position Lloyd-Max codebook already minimizes distortion over the actual weight distribution, and the Hadamard rotation ensures the codebook sees well-spread inputs. At 2 bits with group-128, the inner product bias is small enough that the downstream perplexity impact is negligible (PPL 1.91 vs 1.85). Adding QJL would cost an extra bit per dimension for a correction that isn't needed at this operating point.

**Why per-position codebooks instead of per-coordinate?** TurboQuant can use a single precomputed quantizer because random rotation makes all coordinates identically distributed (each coordinate of a uniform unit-sphere vector follows a known distribution that converges to N(0,1/d) in high dimensions). Hadamard rotation concentrates coordinates but doesn't make them identically distributed — there are structured patterns from the butterfly network. Per-position codebooks (one codebook per group of 128 dimensions, trained across all 262K vocabulary rows at that position) adapt to these patterns. We tried a single joint codebook shared across all positions; per-position was consistently better.

**Why group size 128?** We swept group sizes from 32 to 512. The qualitative tradeoffs:

| Group size | Codebook overhead (bits/elem) | Hadamard cost | Quality |
| --- | --- | --- | --- |
| 32 | 0.500 | fastest | degraded (high overhead eats bit budget) |
| 64 | 0.250 | fast | good |
| **128** | **0.125** | **fast** | **best (sweet spot)** |
| 256 | 0.063 | moderate | slightly worse (less uniform within group) |
| 512 | 0.031 | slow | worse (distribution spreads too thin) |

Group-128 gives 0.125 bits overhead, a fast butterfly, and the best quality. Detailed per-group-size PPL numbers are a target for future work.

## 4\. Results [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#4-results "Permanent link")

### 4.1 Perplexity [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#41-perplexity "Permanent link")

Evaluated on Gemma 4 E2B. Evaluation set: 128 self-generated WildChat-1M completions from our `trajectories.jsonl` calibration set, completion-only NLL, 24,438 scored tokens.

| Variant | Avg bits | PPL |
| --- | --- | --- |
| HuggingFace BF16 | 16 | 1.2892 |
| Cactus default (INT4 linears + INT8 PLI + INT8 token-emb) | ~6.3 | 1.8547 |
| **Cactus + TurboQuant-H PLI** | **~3.8** | **1.9111** |

Perplexity moves from 1.85 to 1.91. A delta of 0.06 PPL on a 24K-token eval set, within noise for practical use. No measured speed regression.

### 4.2 Disk Footprint [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#42-disk-footprint "Permanent link")

| Variant | Size (MB) | Factor |
| --- | --- | --- |
| HuggingFace FP16 snapshot | ~10,240 | 1.00× |
| Cactus default (INT4 linears + INT8 PLI + INT8 emb) | ~4,790 | 0.47× |
| **Cactus + TurboQuant-H PLI** | **2,918** | **0.29×** |

The PLI table specifically: **2,496 MB → 624 MB, a 4× reduction.**

Total LLM weight reduction: **40%** from the Cactus baseline. Including the vision and audio encoders (untouched by this change), the overall model reduction is **30%**.

For Gemma 4 E2B, that's the difference between a 4.8 GB model and a 2.9 GB model. On a 4 GB RAM Android device, that's the difference between fitting and not fitting.

For Gemma-270m, where the embedding table (295M params) is larger than all other weights combined, we expect the same technique to cut total model size roughly in half. Validation on Gemma-270m is planned future work.

## 5\. Inference Path [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#5-inference-path "Permanent link")

### 5.1 Before (Cactus default) [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#51-before-cactus-default "Permanent link")

```
token_ids → gather from INT8 table → dequantize to FP16 → feed to transformer
```

### 5.2 After (Cactus TurboQuant-H) [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#52-after-cactus-turboquant-h "Permanent link")

```
token_ids → gather 2-bit indices → scatter codebook → Hadamard rotation → FP16 → transformer
```

### 5.3 Overhead Analysis [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#53-overhead-analysis "Permanent link")

The Hadamard butterfly on a group of G=128 elements has log2⁡(G)=7 stages. Each stage performs G/2=64 add/subtract pairs (the butterfly operations). Over 7 stages that is 7×64=448 add/sub operations per group. On ARM NEON (128-bit SIMD, 8 FP16 lanes), each stage processes the group in G/(2×8)=8 vector instructions, giving 7×8=56 vector operations per group.

For a single PLI embedding row of D=8,190 elements:

Groups per row=⌈8190/128⌉=64

Total vector ops=64×56=3,584

At one vector add/sub per cycle on a 2 GHz A15 NEON unit, this completes in under 2 microseconds per embedding lookup. The gather from a table that is 8/2.125≈3.8× smaller in memory more than compensates for the rotation cost in bandwidth savings.

## 6\. Related Work [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#6-related-work "Permanent link")

**TurboQuant** (Zandieh et al., ICLR 2026) introduced data-oblivious vector quantization with random rotation and QJL correction for KV cache compression, achieving near-optimal distortion rates within a constant factor of ≈2.7 from information-theoretic lower bounds.

**QuIP#** (Tseng et al., 2024) uses the randomized Hadamard transform for weight quantization of linear layers, but does not address embedding tables or per-layer embeddings.

**GPTQ, AWQ** focus on linear layer weight quantization with calibration data. These methods do not handle embedding tables, which are pure lookup operations with no gradient flow during inference.

To our knowledge, TurboQuant-H is the first application of rotation-based vector quantization specifically to per-layer embedding tables, which is where the technique yields the largest storage benefit due to the embedding-dominated weight distribution in AltUp architectures.

## 7\. Next Steps [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#7-next-steps "Permanent link")

This is a research preview of ongoing work at Cactus. Here's what's coming:

1. **Downstream task validation.** The 0.06 PPL increase is promising, but we're running full evals (MMLU, IFEval, GPQA) across Gemma-270m, Gemma 3n, and Gemma 4 E4B to confirm TurboQuant-H holds up on real tasks, not just perplexity.
2. **Extend to shared `token_embeddings`.** TurboQuant-H currently targets PLI tables only. Applying it to the shared embedding table (408 MB) is straightforward and would push total compression further.
3. **Quantitative group size sweep.** Section 3.4 reports qualitative tradeoffs. We're collecting per-group-size PPL numbers to give a rigorous recommendation.
4. **1-bit with QJL correction.** At 1-bit, the theoretical compression reaches 8x on PLI tables. We're evaluating whether reintroducing the QJL residual stage at this extreme bit width recovers enough quality to be practical.
5. **Ship TurboQuant-H weights.** Integrate the quantization path into `cactus convert` and publish pre-quantized weights on HuggingFace for all supported Gemma E-series models.

## Try It [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#try-it "Permanent link")

Run Gemma 4 today on Cactus:

```
brew install cactus-compute/cactus/cactus
cactus run google/gemma-4-E2B-it
```

TurboQuant-H PLI weights will ship in an upcoming release. If you're working on embedding quantization or have thoughts on extending this to the shared token embedding table, open an issue on [GitHub](https://github.com/cactus-compute/cactus).

## Citation [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#citation "Permanent link")

If you use TurboQuant-H in your research, please cite:

```
@article{turboquant-h,
  title     = {TurboQuant-H: Hadamard Rotation for 2-Bit Embedding
               Quantization in Embedding-Dominated Models},
  author    = {Mosoyan, Karen and Ndubuaku, Henry},
  year      = {2026},
  url       = {https://docs.cactuscompute.com/latest/blog/turboquant-h/},
  note      = {Cactus Compute Research Preview}
}
```

## References [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#references "Permanent link")

- Zandieh, Daliri, Hadian, Mirrokni. [TurboQuant: Online Vector Quantization with Near-optimal Distortion Rate](https://arxiv.org/abs/2504.19874). ICLR 2026.
- Tseng et al. QuIP#: Even Better LLM Quantization with Hadamard Incoherence and Lattice Codebooks. 2024.
- Google Gemma Team. Gemma 3n / Gemma 4 Technical Reports. 2026.

## See Also [¶](https://docs.cactuscompute.com/latest/blog/turboquant-h/\#see-also "Permanent link")

- [Gemma 4 on Cactus](https://docs.cactuscompute.com/latest/blog/gemma4/) — Day-one multimodal support with vision, audio, and hybrid inference
- [LFM-2.5-350m on Cactus](https://docs.cactuscompute.com/latest/blog/lfm2.5_350m/) — INT8 quantization deep dive and zero-copy loading
- [Cactus Engine API](https://docs.cactuscompute.com/latest/docs/cactus_engine/) — Full C API reference

Back to top
[Previous\\
\\
\\
All Posts](https://docs.cactuscompute.com/latest/blog/) [Next\\
\\
\\
Gemma 4 on Cactus](https://docs.cactuscompute.com/latest/blog/gemma4/)



Made with
[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)

[github.com](https://github.com/cactus-compute/cactus "github.com")[www.reddit.com](https://www.reddit.com/r/cactuscompute/ "www.reddit.com")