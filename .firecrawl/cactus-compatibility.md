[Skip to content](https://docs.cactuscompute.com/latest/docs/compatibility/#runtime-weights-compatibility)


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


Runtime & Weights Compatibility



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

- [x]


Guides






Guides




  - [Fine-tuning & Deployment](https://docs.cactuscompute.com/latest/docs/finetuning/)
  - [ ]


     Runtime Compatibility



     [Runtime Compatibility](https://docs.cactuscompute.com/latest/docs/compatibility/)
     Table of contents


    - [How Versioning Works](https://docs.cactuscompute.com/latest/docs/compatibility/#how-versioning-works)
    - [Checking Compatibility](https://docs.cactuscompute.com/latest/docs/compatibility/#checking-compatibility)
    - [See Also](https://docs.cactuscompute.com/latest/docs/compatibility/#see-also)

- [Contributing](https://docs.cactuscompute.com/latest/CONTRIBUTING/)
- [ ]


Blog






Blog




  - [All Posts](https://docs.cactuscompute.com/latest/blog/)
  - [TurboQuant-H](https://docs.cactuscompute.com/latest/blog/turboquant-h/)
  - [Gemma 4 on Cactus](https://docs.cactuscompute.com/latest/blog/gemma4/)
  - [Hybrid Transcription](https://docs.cactuscompute.com/latest/blog/hybrid_transcription/)
  - [LFM2-24B on Mac](https://docs.cactuscompute.com/latest/blog/lfm2_24b_a2b/)
  - [Parakeet CTC 1.1B](https://docs.cactuscompute.com/latest/blog/parakeet/)
  - [LFM-2.5-350m](https://docs.cactuscompute.com/latest/blog/lfm2.5_350m/)

Table of contents


- [How Versioning Works](https://docs.cactuscompute.com/latest/docs/compatibility/#how-versioning-works)
- [Checking Compatibility](https://docs.cactuscompute.com/latest/docs/compatibility/#checking-compatibility)
- [See Also](https://docs.cactuscompute.com/latest/docs/compatibility/#see-also)

# Runtime & Weights Compatibility [¶](https://docs.cactuscompute.com/latest/docs/compatibility/\#runtime-weights-compatibility "Permanent link")

Some Cactus releases change the internal weight format. When this happens, cached weights from an older version will not load with a newer runtime and must be re-downloaded.

Breaking weight changes are called out in the [release notes](https://github.com/cactus-compute/cactus/releases).

## How Versioning Works [¶](https://docs.cactuscompute.com/latest/docs/compatibility/\#how-versioning-works "Permanent link")

Weights are published to [Hugging Face](https://huggingface.co/Cactus-Compute) and **only re-tagged when they actually change**. If a release does not affect the weight format, the previous tag remains — no new upload.

```
Runtime v1.7  -> weights tagged v1.7 on HF
Runtime v1.8  -> no new tag (unchanged) - still use v1.7
...
Runtime v1.14 -> no new tag - still use v1.7
Runtime v1.15 -> new tag v1.15 (changed!) - must update
```

**The rule:** use the latest HF weight tag that is ≤ your runtime version.

## Checking Compatibility [¶](https://docs.cactuscompute.com/latest/docs/compatibility/\#checking-compatibility "Permanent link")

1. Open your model on [huggingface.co/Cactus-Compute](https://huggingface.co/Cactus-Compute)
2. Click **Files and versions → open branch dropdown from Main**
3. Find the latest tag that is ≤ your runtime version
4. If your local weights use an older tag, re-download them

## See Also [¶](https://docs.cactuscompute.com/latest/docs/compatibility/\#see-also "Permanent link")

- [Cactus Engine API](https://docs.cactuscompute.com/latest/docs/cactus_engine/) — Full inference API reference
- [Fine-tuning Guide](https://docs.cactuscompute.com/latest/docs/finetuning/) — Convert and deploy custom fine-tunes
- [HuggingFace Weights](https://huggingface.co/Cactus-Compute) — Official Cactus model weights

Back to top
[Previous\\
\\
\\
Fine-tuning & Deployment](https://docs.cactuscompute.com/latest/docs/finetuning/) [Next\\
\\
\\
Contributing](https://docs.cactuscompute.com/latest/CONTRIBUTING/)



Made with
[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)

[github.com](https://github.com/cactus-compute/cactus "github.com")[www.reddit.com](https://www.reddit.com/r/cactuscompute/ "www.reddit.com")