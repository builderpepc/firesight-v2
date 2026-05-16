[Skip to content](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus-engine-ffi-documentation)


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


Cactus Engine FFI API Reference



Type to start searching

[cactus-compute/cactus\\
\\
\\
- v1.14\\
- 4.9k\\
- 383](https://github.com/cactus-compute/cactus "Go to repository")

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

- [x]


Core APIs (C++)






Core APIs (C++)




  - [ ]


     Engine API



     [Engine API](https://docs.cactuscompute.com/latest/docs/cactus_engine/)
     Table of contents


    - [Getting Started](https://docs.cactuscompute.com/latest/docs/cactus_engine/#getting-started)
    - [Types](https://docs.cactuscompute.com/latest/docs/cactus_engine/#types)

      - [cactus\_model\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_model_t)
      - [cactus\_index\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_t)
      - [cactus\_stream\_transcribe\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_t)
      - [cactus\_token\_callback](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_token_callback)
      - [cactus\_log\_callback\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_log_callback_t)

    - [Core Functions](https://docs.cactuscompute.com/latest/docs/cactus_engine/#core-functions)

      - [cactus\_init](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_init)
      - [cactus\_complete](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_complete)
      - [cactus\_prefill](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_prefill)
      - [cactus\_tokenize](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_tokenize)
      - [cactus\_score\_window](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_score_window)
      - [cactus\_transcribe](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_transcribe)
      - [cactus\_stream\_transcribe\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_t_1)
      - [cactus\_stream\_transcribe\_start](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_start)
      - [cactus\_stream\_transcribe\_process](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_process)
      - [cactus\_stream\_transcribe\_stop](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_stop)
      - [cactus\_diarize](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_diarize)
      - [cactus\_embed\_speaker](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_embed_speaker)
      - [cactus\_detect\_language](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_detect_language)
      - [cactus\_vad](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_vad)
      - [cactus\_embed](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_embed)
      - [cactus\_image\_embed](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_image_embed)
      - [cactus\_audio\_embed](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_audio_embed)
      - [cactus\_stop](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stop)
      - [cactus\_reset](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_reset)
      - [cactus\_rag\_query](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_rag_query)
      - [cactus\_destroy](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_destroy)

    - [Utility Functions](https://docs.cactuscompute.com/latest/docs/cactus_engine/#utility-functions)

      - [cactus\_get\_last\_error](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_get_last_error)

    - [Vector Index APIs](https://docs.cactuscompute.com/latest/docs/cactus_engine/#vector-index-apis)

      - [cactus\_index\_init](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_init)
      - [cactus\_index\_add](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_add)
      - [cactus\_index\_delete](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_delete)
      - [cactus\_index\_get](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_get)
      - [cactus\_index\_query](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_query)
      - [cactus\_index\_compact](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_compact)
      - [cactus\_index\_destroy](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_destroy)
      - [Complete RAG Example](https://docs.cactuscompute.com/latest/docs/cactus_engine/#complete-rag-example)

    - [Complete Examples](https://docs.cactuscompute.com/latest/docs/cactus_engine/#complete-examples)

      - [Basic Conversation](https://docs.cactuscompute.com/latest/docs/cactus_engine/#basic-conversation)
      - [Vision-Language Model (VLM)](https://docs.cactuscompute.com/latest/docs/cactus_engine/#vision-language-model-vlm)
      - [Tool Calling](https://docs.cactuscompute.com/latest/docs/cactus_engine/#tool-calling)
      - [Computing Similarity with Embeddings](https://docs.cactuscompute.com/latest/docs/cactus_engine/#computing-similarity-with-embeddings)
      - [Audio Transcription with Whisper](https://docs.cactuscompute.com/latest/docs/cactus_engine/#audio-transcription-with-whisper)
      - [Multimodal Retrieval](https://docs.cactuscompute.com/latest/docs/cactus_engine/#multimodal-retrieval)

    - [Supported Model Types](https://docs.cactuscompute.com/latest/docs/cactus_engine/#supported-model-types)
    - [Environment Variables](https://docs.cactuscompute.com/latest/docs/cactus_engine/#environment-variables)
    - [Best Practices](https://docs.cactuscompute.com/latest/docs/cactus_engine/#best-practices)
    - [Error Handling](https://docs.cactuscompute.com/latest/docs/cactus_engine/#error-handling)
    - [Performance Tips](https://docs.cactuscompute.com/latest/docs/cactus_engine/#performance-tips)
    - [Logging](https://docs.cactuscompute.com/latest/docs/cactus_engine/#logging)

      - [cactus\_log\_set\_level](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_log_set_level)
      - [cactus\_log\_set\_callback](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_log_set_callback)

    - [Telemetry](https://docs.cactuscompute.com/latest/docs/cactus_engine/#telemetry)

      - [cactus\_set\_telemetry\_environment](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_set_telemetry_environment)
      - [cactus\_set\_app\_id](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_set_app_id)
      - [cactus\_telemetry\_flush](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_telemetry_flush)
      - [cactus\_telemetry\_shutdown](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_telemetry_shutdown)

    - [See Also](https://docs.cactuscompute.com/latest/docs/cactus_engine/#see-also)

  - [Graph API](https://docs.cactuscompute.com/latest/docs/cactus_graph/)
  - [Index API](https://docs.cactuscompute.com/latest/docs/cactus_index/)

- [ ]


Guides






Guides




  - [Fine-tuning & Deployment](https://docs.cactuscompute.com/latest/docs/finetuning/)
  - [Runtime Compatibility](https://docs.cactuscompute.com/latest/docs/compatibility/)

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


- [Getting Started](https://docs.cactuscompute.com/latest/docs/cactus_engine/#getting-started)
- [Types](https://docs.cactuscompute.com/latest/docs/cactus_engine/#types)

  - [cactus\_model\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_model_t)
  - [cactus\_index\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_t)
  - [cactus\_stream\_transcribe\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_t)
  - [cactus\_token\_callback](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_token_callback)
  - [cactus\_log\_callback\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_log_callback_t)

- [Core Functions](https://docs.cactuscompute.com/latest/docs/cactus_engine/#core-functions)

  - [cactus\_init](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_init)
  - [cactus\_complete](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_complete)
  - [cactus\_prefill](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_prefill)
  - [cactus\_tokenize](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_tokenize)
  - [cactus\_score\_window](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_score_window)
  - [cactus\_transcribe](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_transcribe)
  - [cactus\_stream\_transcribe\_t](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_t_1)
  - [cactus\_stream\_transcribe\_start](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_start)
  - [cactus\_stream\_transcribe\_process](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_process)
  - [cactus\_stream\_transcribe\_stop](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stream_transcribe_stop)
  - [cactus\_diarize](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_diarize)
  - [cactus\_embed\_speaker](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_embed_speaker)
  - [cactus\_detect\_language](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_detect_language)
  - [cactus\_vad](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_vad)
  - [cactus\_embed](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_embed)
  - [cactus\_image\_embed](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_image_embed)
  - [cactus\_audio\_embed](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_audio_embed)
  - [cactus\_stop](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_stop)
  - [cactus\_reset](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_reset)
  - [cactus\_rag\_query](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_rag_query)
  - [cactus\_destroy](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_destroy)

- [Utility Functions](https://docs.cactuscompute.com/latest/docs/cactus_engine/#utility-functions)

  - [cactus\_get\_last\_error](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_get_last_error)

- [Vector Index APIs](https://docs.cactuscompute.com/latest/docs/cactus_engine/#vector-index-apis)

  - [cactus\_index\_init](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_init)
  - [cactus\_index\_add](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_add)
  - [cactus\_index\_delete](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_delete)
  - [cactus\_index\_get](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_get)
  - [cactus\_index\_query](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_query)
  - [cactus\_index\_compact](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_compact)
  - [cactus\_index\_destroy](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_index_destroy)
  - [Complete RAG Example](https://docs.cactuscompute.com/latest/docs/cactus_engine/#complete-rag-example)

- [Complete Examples](https://docs.cactuscompute.com/latest/docs/cactus_engine/#complete-examples)

  - [Basic Conversation](https://docs.cactuscompute.com/latest/docs/cactus_engine/#basic-conversation)
  - [Vision-Language Model (VLM)](https://docs.cactuscompute.com/latest/docs/cactus_engine/#vision-language-model-vlm)
  - [Tool Calling](https://docs.cactuscompute.com/latest/docs/cactus_engine/#tool-calling)
  - [Computing Similarity with Embeddings](https://docs.cactuscompute.com/latest/docs/cactus_engine/#computing-similarity-with-embeddings)
  - [Audio Transcription with Whisper](https://docs.cactuscompute.com/latest/docs/cactus_engine/#audio-transcription-with-whisper)
  - [Multimodal Retrieval](https://docs.cactuscompute.com/latest/docs/cactus_engine/#multimodal-retrieval)

- [Supported Model Types](https://docs.cactuscompute.com/latest/docs/cactus_engine/#supported-model-types)
- [Environment Variables](https://docs.cactuscompute.com/latest/docs/cactus_engine/#environment-variables)
- [Best Practices](https://docs.cactuscompute.com/latest/docs/cactus_engine/#best-practices)
- [Error Handling](https://docs.cactuscompute.com/latest/docs/cactus_engine/#error-handling)
- [Performance Tips](https://docs.cactuscompute.com/latest/docs/cactus_engine/#performance-tips)
- [Logging](https://docs.cactuscompute.com/latest/docs/cactus_engine/#logging)

  - [cactus\_log\_set\_level](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_log_set_level)
  - [cactus\_log\_set\_callback](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_log_set_callback)

- [Telemetry](https://docs.cactuscompute.com/latest/docs/cactus_engine/#telemetry)

  - [cactus\_set\_telemetry\_environment](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_set_telemetry_environment)
  - [cactus\_set\_app\_id](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_set_app_id)
  - [cactus\_telemetry\_flush](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_telemetry_flush)
  - [cactus\_telemetry\_shutdown](https://docs.cactuscompute.com/latest/docs/cactus_engine/#cactus_telemetry_shutdown)

- [See Also](https://docs.cactuscompute.com/latest/docs/cactus_engine/#see-also)

# Cactus Engine FFI Documentation [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus-engine-ffi-documentation "Permanent link")

The Cactus Engine provides a clean C FFI (Foreign Function Interface) for integrating the LLM inference engine into various applications. This documentation covers all available functions, their parameters, and usage examples.

## Getting Started [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#getting-started "Permanent link")

Before using the Cactus Engine, you need to download model weights:

```
./setup
cactus download LiquidAI/LFM2-1.2B
cactus download LiquidAI/LFM2-VL-450M
cactus download openai/whisper-small
cactus download UsefulSensors/moonshine-base --precision FP16

# Optional: set your Cactus Cloud API key for automatic cloud fallback
cactus auth
```

Weights are saved to the `weights/` directory and can be loaded using `cactus_init()`.
Moonshine requires FP16 precision when downloading and running.

## Types [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#types "Permanent link")

### `cactus_model_t` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_model_t "Permanent link")

An opaque pointer type representing a loaded model instance. This handle is used throughout the API to reference a specific model.

```
typedef void* cactus_model_t;
```

### `cactus_index_t` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_index_t "Permanent link")

An opaque pointer type representing a vector index instance.

```
typedef void* cactus_index_t;
```

### `cactus_stream_transcribe_t` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_stream_transcribe_t "Permanent link")

An opaque pointer type representing a streaming transcription session.

```
typedef void* cactus_stream_transcribe_t;
```

### `cactus_token_callback` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_token_callback "Permanent link")

Callback function type for streaming token generation. Called for each generated token during completion.

```
typedef void (*cactus_token_callback)(
    const char* token,      // The generated token text
    uint32_t token_id,      // The token's ID in the vocabulary
    void* user_data         // User-provided context data
);
```

### `cactus_log_callback_t` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_log_callback_t "Permanent link")

Callback function type for log messages. Installed via `cactus_log_set_callback`.

```
typedef void (*cactus_log_callback_t)(int level, const char* component, const char* message, void* user_data);
```

## Core Functions [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#core-functions "Permanent link")

### `cactus_init` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_init "Permanent link")

Initializes a model from disk and prepares it for inference.

```
cactus_model_t cactus_init(
    const char* model_path,   // Path to the model directory
    const char* corpus_dir,   // Optional path to corpus directory for RAG (can be NULL)
    bool cache_index          // false = always rebuild index, true = load cached if available
);
```

**Returns:** Model handle on success, NULL on failure

**Example:**

```
cactus_model_t model = cactus_init("../../weights/qwen3-600m", NULL, false);
if (!model) {
    fprintf(stderr, "Failed to initialize model\n");
    return -1;
}

// with RAG corpus
cactus_model_t rag_model = cactus_init("../../weights/lfm2-rag", "./documents", true);
```

### `cactus_complete` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_complete "Permanent link")

Performs text completion with optional streaming and tool support.

```
int cactus_complete(
    cactus_model_t model,           // Model handle
    const char* messages_json,      // JSON array of messages
    char* response_buffer,          // Buffer for response JSON
    size_t buffer_size,             // Size of response buffer
    const char* options_json,       // Optional generation options (can be NULL)
    const char* tools_json,         // Optional tools definition (can be NULL)
    cactus_token_callback callback, // Optional streaming callback (can be NULL)
    void* user_data,                // User data for callback (can be NULL)
    const uint8_t* pcm_buffer,     // Optional raw PCM audio buffer (can be NULL)
    size_t pcm_buffer_size         // Size of PCM buffer in bytes (0 when not used)
);
```

**Returns:** Number of bytes written to response\_buffer on success, negative value on error

**Message Format:**

```
[\
    {"role": "system", "content": "You are a helpful assistant."},\
    {"role": "user", "content": "What is your name?"}\
]
```

**Messages with Images (for VLM models):**

```
[\
    {"role": "user", "content": "Describe this image", "images": ["/path/to/image.jpg"]}\
]
```

**Messages with Audio (for multimodal models like Gemma4):**

```
[\
    {"role": "user", "content": "Transcribe the audio.", "audio": ["/path/to/audio.wav"]}\
]
```

**Messages with Images and Audio:**

```
[\
    {"role": "user", "content": "Describe the image and transcribe the audio.", "images": ["/path/to/image.jpg"], "audio": ["/path/to/audio.wav"]}\
]
```

**Options Format:**

```
{
    "max_tokens": 256,
    "temperature": 0.7,
    "top_p": 0.95,
    "min_p": 0.15,
    "repetition_penalty": 1.1,
    "top_k": 40,
    "stop_sequences": ["<|im_end|>", "<end_of_turn>"],
    "include_stop_sequences": false,
    "force_tools": false,
    "tool_rag_top_k": 2,
    "confidence_threshold": 0.7,
    "auto_handoff": true,
    "cloud_timeout_ms": 15000,
    "handoff_with_images": true,
    "enable_thinking_if_supported": false
}
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `max_tokens` | int | 100 | Maximum tokens to generate |
| `temperature` | float | 0.0 | Sampling temperature |
| `top_p` | float | 0.0 | Top-p (nucleus) sampling |
| `top_k` | int | 0 | Top-k sampling |
| `min_p` | float | 0.15 | Minimum probability threshold relative to max probability |
| `repetition_penalty` | float | 1.1 | Penalize previously generated tokens (1.0 disables) |
| `stop_sequences` | array | \[\] | Stop generation on these strings |
| `include_stop_sequences` | bool | false | Include stop sequence tokens in the response |
| `force_tools` | bool | false | Constrain output to tool call format |
| `tool_rag_top_k` | int | 2 | Select top-k relevant tools via Tool RAG (0 = disabled, use all tools) |
| `confidence_threshold` | float | 0.7 | Minimum confidence for local generation; triggers cloud\_handoff when below |
| `auto_handoff` | bool | true | Automatically attempt cloud handoff when confidence is low |
| `cloud_timeout_ms` | int | 15000 | Timeout in milliseconds for cloud handoff requests |
| `handoff_with_images` | bool | true | Allow cloud handoff for requests that include images |
| `enable_thinking_if_supported` | bool | false | Enable chain-of-thought thinking blocks for models that support it |

**Response Format:**

```
{
    "success": true,
    "error": null,
    "cloud_handoff": false,
    "response": "I am an AI assistant.",
    "function_calls": [],
    "segments": [],
    "confidence": 0.85,
    "time_to_first_token_ms": 150.5,
    "total_time_ms": 1250.3,
    "prefill_tps": 166.1,
    "decode_tps": 45.2,
    "ram_usage_mb": 245.67,
    "prefill_tokens": 25,
    "decode_tokens": 8,
    "total_tokens": 33
}
```

The `thinking` field is only present in the JSON when the model produced a chain-of-thought block:

```
{
    "success": true,
    "error": null,
    "cloud_handoff": false,
    "response": "The answer is 4.",
    "thinking": "Let me consider this... 2+2 equals 4.",
    "function_calls": [],
    "segments": [],
    "confidence": 0.91,
    "time_to_first_token_ms": 150.5,
    "total_time_ms": 1250.3,
    "prefill_tps": 166.1,
    "decode_tps": 45.2,
    "ram_usage_mb": 245.67,
    "prefill_tokens": 25,
    "decode_tokens": 8,
    "total_tokens": 33
}
```

**Cloud Handoff Response** (when model detects low confidence and cloud handoff succeeds):

```
{
    "success": true,
    "error": null,
    "cloud_handoff": true,
    "response": "Cloud-provided answer.",
    "function_calls": [],
    "segments": [],
    "confidence": 0.18,
    "time_to_first_token_ms": 45.2,
    "total_time_ms": 45.2,
    "prefill_tps": 619.5,
    "decode_tps": 0.0,
    "ram_usage_mb": 245.67,
    "prefill_tokens": 28,
    "decode_tokens": 0,
    "total_tokens": 28
}
```

When `cloud_handoff` is true, the model's confidence dropped below `confidence_threshold` (default: 0.7) and the response was fulfilled by a cloud-based model. The `response` field contains the cloud-provided answer.

**Error Response:**

```
{
    "success": false,
    "error": "Error message here",
    "cloud_handoff": false,
    "response": null,
    "function_calls": [],
    "confidence": 0.0,
    "time_to_first_token_ms": 0.0,
    "total_time_ms": 0.0,
    "prefill_tps": 0.0,
    "decode_tps": 0.0,
    "ram_usage_mb": 245.67,
    "prefill_tokens": 0,
    "decode_tokens": 0,
    "total_tokens": 0
}
```

Note: `ram_usage_mb` reflects actual current RAM usage even in error responses.

**Response with Function Call:**

```
{
    "success": true,
    "error": null,
    "cloud_handoff": false,
    "response": "",
    "function_calls": [\
        {\
            "name": "get_weather",\
            "arguments": {"location": "San Francisco, CA, USA"}\
        }\
    ],
    "segments": [],
    "confidence": 0.92,
    "time_to_first_token_ms": 120.0,
    "total_time_ms": 450.5,
    "prefill_tps": 375.0,
    "decode_tps": 38.5,
    "ram_usage_mb": 245.67,
    "prefill_tokens": 45,
    "decode_tokens": 15,
    "total_tokens": 60
}
```

**Example with Streaming:**

```
void streaming_callback(const char* token, uint32_t token_id, void* user_data) {
    printf("%s", token);
    fflush(stdout);
}

const char* messages = "[{\"role\": \"user\", \"content\": \"Tell me a story\"}]";

char response[8192];
int result = cactus_complete(model, messages, response, sizeof(response),
                             NULL, NULL, streaming_callback, NULL, NULL, 0);
```

### `cactus_prefill` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_prefill "Permanent link")

Pre-processes input text and populates the KV cache without generating output tokens. This reduces latency for future calls to `cactus_complete`.

```
int cactus_prefill(
    cactus_model_t model,           // Model handle
    const char* messages_json,      // JSON array of messages
    char* response_buffer,         // Buffer for response JSON
    size_t buffer_size,             // Size of response buffer
    const char* options_json,       // Optional generation options (can be NULL)
    const char* tools_json,         // Optional tools definition (can be NULL)
    const uint8_t* pcm_buffer,     // Optional raw PCM audio buffer (can be NULL)
    size_t pcm_buffer_size         // Size of PCM buffer in bytes (0 when not used)
);
```

**Returns:** Number of bytes written to response\_buffer on success, negative value on error.

**Message Format:** Same as `cactus_complete` (see above)

**Options Format:** Same as `cactus_complete` (see above)

**Response Format:**

```
{
    "success": true,
    "error": null,
    "prefill_tokens": 25,
    "prefill_tps": 166.1,
    "total_time_ms": 150.5,
    "ram_usage_mb": 245.67
}
```

**Error Response:**

```
{
    "success": false,
    "error": "Error message here",
    "prefill_tokens": 0,
    "prefill_tps": 0.0,
    "total_time_ms": 0.0,
    "ram_usage_mb": 245.67
}
```

**Example:**

```
const char* tools = R"([{\
    "type": "function",\
    "function": {\
        "name": "get_weather",\
        "description": "Get weather for a location",\
        "parameters": {\
            "type": "object",\
            "properties": {\
                "location": {"type": "string", "description": "City, State, Country"}\
            },\
            "required": ["location"]\
        }\
    }\
}])";

const char* base_messages = R"([\
    { "role": "system", "content": "You are a helpful assistant." },\
    { "role": "user", "content": "What is the weather in Paris?" },\
    { "role": "assistant", "content": "<|tool_call_start|>get_weather(location=\"Paris\")<|tool_call_end|>" },\
    { "role": "tool", "content": "{\"name\": \"get_weather\", \"content\": \"Sunny, 72°F\"}" },\
    { "role": "assistant", "content": "It's sunny and 72°F in Paris!" }\
])";

char prefill_response[1024];
cactus_prefill(model, base_messages, prefill_response, sizeof(prefill_response), NULL, tools, NULL, 0);

const char* completion_messages = R"([\
    { "role": "system", "content": "You are a helpful assistant." },\
    { "role": "user", "content": "What is the weather in Paris?" },\
    { "role": "assistant", "content": "<|tool_call_start|>get_weather(location=\"Paris\")<|tool_call_end|>" },\
    { "role": "tool", "content": "{\"name\": \"get_weather\", \"content\": \"Sunny, 72°F\"}" },\
    { "role": "assistant", "content": "It's sunny and 72°F in Paris!" },\
    { "role": "user", "content": "What about SF?" }\
])";
char response[4096];
cactus_complete(model, completion_messages, response, sizeof(response), NULL, tools, NULL, NULL, NULL, 0);
```

### `cactus_tokenize` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_tokenize "Permanent link")

Tokenizes text into token IDs using the model's tokenizer.

```
int cactus_tokenize(
    cactus_model_t model,        // Model handle
    const char* text,            // Text to tokenize
    uint32_t* token_buffer,      // Buffer for token IDs
    size_t token_buffer_len,     // Maximum number of tokens buffer can hold
    size_t* out_token_len        // Output: actual number of tokens
);
```

**Returns:** 0 on success; -1 on invalid parameters or tokenization error; -2 if `token_buffer_len` is smaller than the number of tokens produced (but `*out_token_len` is still set to the required count). Pass `NULL` for `token_buffer` and `0` for `token_buffer_len` to query the token count without copying.

**Example:**

```
const char* text = "Hello, world!";
uint32_t tokens[256];
size_t num_tokens = 0;

int result = cactus_tokenize(model, text, tokens, 256, &num_tokens);
if (result == 0) {
    printf("Tokenized into %zu tokens: ", num_tokens);
    for (size_t i = 0; i < num_tokens; i++) {
        printf("%u ", tokens[i]);
    }
    printf("\n");
}
```

### `cactus_score_window` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_score_window "Permanent link")

Scores a window of tokens for perplexity calculation or token probability analysis.

```
int cactus_score_window(
    cactus_model_t model,        // Model handle
    const uint32_t* tokens,      // Array of token IDs
    size_t token_len,            // Total number of tokens
    size_t start,                // Start index of window to score
    size_t end,                  // End index of window to score
    size_t context,              // Context window size
    char* response_buffer,       // Buffer for response JSON
    size_t buffer_size           // Size of response buffer
);
```

**Returns:** Number of bytes written to response\_buffer on success, negative value on error

**Response Format:**

```
{
    "success": true,
    "logprob": -12.3456789012,
    "tokens": 4
}
```

- `logprob`: Total log-probability of the scored token window
- `tokens`: Number of tokens scored in the window

**Example:**

```
uint32_t tokens[256];
size_t num_tokens;
cactus_tokenize(model, "The quick brown fox", tokens, 256, &num_tokens);

char response[4096];
int result = cactus_score_window(model, tokens, num_tokens, 0, num_tokens, 512,
                                  response, sizeof(response));
if (result >= 0) {
    printf("Scores: %s\n", response);
}
```

### `cactus_transcribe` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_transcribe "Permanent link")

Transcribes audio to text. Supports Whisper, Moonshine, and Parakeet models. Supports both file-based and buffer-based audio input.

```
int cactus_transcribe(
    cactus_model_t model,           // Model handle (Whisper, Moonshine, or Parakeet model)
    const char* audio_file_path,    // Path to WAV file (16-bit PCM) - can be NULL if using pcm_buffer
    const char* prompt,             // Optional prompt to guide transcription (can be NULL)
    char* response_buffer,          // Buffer for response JSON
    size_t buffer_size,             // Size of response buffer
    const char* options_json,       // Optional transcription options (can be NULL)
    cactus_token_callback callback, // Optional streaming callback (can be NULL)
    void* user_data,                // User data for callback (can be NULL)
    const uint8_t* pcm_buffer,      // Optional raw PCM audio buffer (can be NULL if using file)
    size_t pcm_buffer_size          // Size of PCM buffer in bytes (must be even and >= 2)
);
```

**Returns:** Number of bytes written to response\_buffer on success, negative value on error

**Note:** Exactly one of `audio_file_path` or `pcm_buffer` must be provided; passing both or neither returns -1. The file path must point to a 16-bit PCM WAV file. The `pcm_buffer` must contain 16-bit signed PCM samples at 16 kHz and `pcm_buffer_size` must be even and at least 2.

**Options Format:**

```
{
    "max_tokens": 448,
    "temperature": 0.0,
    "top_p": 0.0,
    "top_k": 0,
    "use_vad": true,
    "cloud_handoff_threshold": 0.0,
    "custom_vocabulary": ["word1", "word2"],
    "vocabulary_boost": 5.0
}
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `max_tokens` | int | auto | Maximum tokens to generate; defaults to an estimate based on audio length |
| `temperature` | float | 0.0 | Sampling temperature |
| `top_p` | float | 0.0 | Top-p (nucleus) sampling |
| `top_k` | int | 0 | Top-k sampling |
| `use_vad` | bool | true | Split audio using voice activity detection before transcribing |
| `cloud_handoff_threshold` | float | model default | Maximum token entropy norm above which cloud handoff is flagged |
| `custom_vocabulary` | array | \[\] | Words or phrases to boost recognition probability |
| `vocabulary_boost` | float | 5.0 | Log-probability bias for custom\_vocabulary tokens (0.0–20.0) |

**Response Format:**

```
{
    "success": true,
    "error": null,
    "cloud_handoff": false,
    "response": "Transcribed text here.",
    "function_calls": [],
    "segments": [\
        {"start": 0.0, "end": 2.5, "text": "Transcribed text here."}\
    ],
    "confidence": 0.92,
    "time_to_first_token_ms": 120.0,
    "total_time_ms": 450.0,
    "prefill_tps": 50.0,
    "decode_tps": 30.0,
    "ram_usage_mb": 512.34,
    "prefill_tokens": 10,
    "decode_tokens": 15,
    "total_tokens": 25
}
```

- `response`: Full transcription text
- `segments`: Array of `{"start": float, "end": float, "text": string}` objects with timestamps (seconds). Whisper produces phrase-level segments from timestamp tokens; Parakeet TDT produces word-level segments from native TDT frame timing; Parakeet CTC and Moonshine produce one segment per transcription window (consecutive VAD speech regions grouped up to 30 seconds), with `start`/`end` reflecting the window's boundaries in the source audio.
- `cloud_handoff`: true when `cloud_handoff_threshold > 0`, the transcribed text is non-empty and longer than 5 characters, and the peak token entropy norm exceeded `cloud_handoff_threshold`

**Example (file-based):**

```
cactus_model_t whisper = cactus_init("../../weights/whisper-small", NULL, false);

char response[16384];
int result = cactus_transcribe(whisper, "audio.wav", NULL,
                                response, sizeof(response), NULL, NULL, NULL,
                                NULL, 0);
if (result >= 0) {
    printf("Transcription: %s\n", response);
}
```

**Example (buffer-based):**

```
uint8_t* pcm_data = load_audio_buffer("audio.wav", &pcm_size); // 16kHz, mono, 16-bit

char response[16384];
int result = cactus_transcribe(whisper, NULL, NULL,
                                response, sizeof(response), NULL, NULL, NULL,
                                pcm_data, pcm_size);
```

**Transcription Options Format:**

```
{
    "max_tokens": 100,
    "custom_vocabulary": ["Omeprazole", "HIPAA", "Cactus"],
    "vocabulary_boost": 3.0
}
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `max_tokens` | int | 448 | Maximum tokens to generate |
| `custom_vocabulary` | array | \[\] | List of words or phrases to bias the decoder toward. Useful for proper nouns, acronyms, medical terms, and domain-specific jargon. |
| `vocabulary_boost` | float | 5.0 | Logit bias strength applied to tokens from `custom_vocabulary`. Clamped to 0.0–20.0. Higher values make the listed words more likely to appear. |

**Note:** Custom vocabulary biasing is supported for Whisper and Moonshine models. Each vocabulary entry is tokenized into sub-tokens and the boost is applied per-token at each decoder step.

**Example (with custom vocabulary):**

```
cactus_model_t whisper = cactus_init("../../weights/whisper-small", NULL, false);

const char* options = "{\"custom_vocabulary\": [\"Omeprazole\", \"HIPAA\", \"Cactus\"], \"vocabulary_boost\": 3.0}";

char response[16384];
int result = cactus_transcribe(whisper, "medical_notes.wav", NULL,
                                response, sizeof(response), options, NULL, NULL,
                                NULL, 0);
if (result > 0) {
    printf("Transcription: %s\n", response);
}
```

### `cactus_stream_transcribe_t` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_stream_transcribe_t_1 "Permanent link")

An opaque pointer type representing a streaming transcription session. Used for real-time audio transcription with incremental confirmation.

```
typedef void* cactus_stream_transcribe_t;
```

### `cactus_stream_transcribe_start` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_stream_transcribe_start "Permanent link")

Initializes a new streaming transcription session with optional configuration.

```
cactus_stream_transcribe_t cactus_stream_transcribe_start(
    cactus_model_t model,        // Model handle
    const char* options_json     // Optional configuration (can be NULL)
);
```

**Returns:** Stream handle on success, NULL on failure

**Options Format:**

```
{
    "min_chunk_size": 32000,
    "language": "en",
    "custom_vocabulary": ["Omeprazole", "HIPAA", "Cactus"],
    "vocabulary_boost": 3.0
}
```

- `min_chunk_size`: Minimum number of audio samples (as int16 samples) required before a transcription processing step is triggered. Default: 32000
- `language`: ISO 639-1 language code (e.g., "en", "es", "fr", "de"). Default: "en". Ignored for non-Whisper models.
- `custom_vocabulary`: List of words or phrases to bias the decoder toward. Useful for proper nouns, acronyms, and domain-specific terms. The bias is applied for the lifetime of the stream session.
- `vocabulary_boost`: Logit bias strength for `custom_vocabulary` tokens. Default: 5.0. Clamped to 0.0–20.0.

**Example:**

```
cactus_model_t whisper = cactus_init("../../weights/whisper-small", NULL, false);

cactus_stream_transcribe_t stream = cactus_stream_transcribe_start(whisper, "{\"min_chunk_size\": 32000, \"language\": \"en\"}");
if (!stream) {
    fprintf(stderr, "Failed to start stream: %s\n", cactus_get_last_error());
    return -1;
}
```

**Example (with custom vocabulary):**

```
const char* options = "{\"confirmation_threshold\": 0.99, \"custom_vocabulary\": [\"Omeprazole\", \"HIPAA\"], \"vocabulary_boost\": 5.0}";
cactus_stream_transcribe_t stream = cactus_stream_transcribe_start(whisper, options);
```

### `cactus_stream_transcribe_process` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_stream_transcribe_process "Permanent link")

Processes audio chunk and returns confirmed and pending transcription results.

```
int cactus_stream_transcribe_process(
    cactus_stream_transcribe_t stream,  // Stream handle
    const uint8_t* pcm_buffer,          // Raw PCM audio (16-bit, 16kHz, mono)
    size_t pcm_buffer_size,             // Size of PCM buffer in bytes
    char* response_buffer,              // Buffer for response JSON
    size_t buffer_size                  // Size of response buffer
);
```

**Returns:** Number of bytes written to response\_buffer on success, negative value on error

When the accumulated audio has not yet reached `min_chunk_size`, a minimal buffering response is returned immediately (no inference is run):

```
{"success": true, "confirmed": "", "pending": ""}
```

When a transcription step is triggered, the full response is returned:

**Response Format:**

```
{
    "success": true,
    "buffer_duration_ms": 1000.0,
    "error": null,
    "cloud_handoff": false,
    "cloud_job_id": 0,
    "cloud_result_job_id": 0,
    "cloud_result": "",
    "cloud_result_used_cloud": false,
    "cloud_result_error": null,
    "cloud_result_source": "fallback",
    "confirmed_local": "text confirmed from local model",
    "confirmed": "text confirmed (may be from cloud if cloud was used)",
    "pending": "current transcription result",
    "segments": [],
    "function_calls": [],
    "confidence": 0.95,
    "time_to_first_token_ms": 150.5,
    "total_time_ms": 450.2,
    "prefill_tps": 100.0,
    "decode_tps": 50.0,
    "ram_usage_mb": 512.5,
    "prefill_tokens": 100,
    "decode_tokens": 50,
    "total_tokens": 150
}
```

- `buffer_duration_ms`: Duration of the confirmed audio that has been consumed from the buffer (milliseconds)
- `confirmed`: Confirmed transcription text from this chunk; if a cloud job returned a result it may reflect the cloud transcript
- `confirmed_local`: The confirmed text as produced by the local model (before any cloud override)
- `pending`: Current (not yet confirmed) transcription result from the latest inference pass
- `segments`: Array of `{"start": float, "end": float, "text": string}` objects representing transcription segments with timestamps (in seconds, relative to the start of the stream). Whisper produces phrase-level segments; Parakeet TDT produces word-level segments; Parakeet CTC and Moonshine produce one segment per transcription window (consecutive VAD speech regions grouped up to 30 seconds).
- `cloud_handoff`: Whether a cloud transcription job was queued for the confirmed audio
- `cloud_job_id`: ID of the cloud job queued in this call (0 if none)
- `cloud_result_job_id`: ID of the cloud job whose result is returned in this response (0 if none ready)
- `cloud_result`: Transcript returned by the completed cloud job (empty if no result ready)
- `cloud_result_used_cloud`: Whether the completed cloud job actually reached a cloud API
- `cloud_result_error`: Error message from the cloud job, null if none
- `cloud_result_source`: `"cloud"` or `"fallback"` for the completed cloud job
- `error`: Error message if any, null otherwise
- `function_calls`: Array of function calls if any
- `confidence`, timing, and token metrics: Model performance statistics from the underlying transcription call

**Example:**

```
uint8_t audio_chunk[32000]; // 1 second at 16kHz, 16-bit
char response[32768];

int result = cactus_stream_transcribe_process(stream, audio_chunk, sizeof(audio_chunk), response, sizeof(response));
if (result >= 0) {
    printf("Response: %s\n", response);
}
```

### `cactus_stream_transcribe_stop` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_stream_transcribe_stop "Permanent link")

Stops the streaming session and returns any remaining confirmed transcription. Releases all resources.

```
int cactus_stream_transcribe_stop(
    cactus_stream_transcribe_t stream,  // Stream handle
    char* response_buffer,              // Buffer for response JSON (can be NULL)
    size_t buffer_size                  // Size of response buffer (can be 0)
);
```

**Returns:** Number of bytes written on success, 0 if no response buffer provided, negative value on error

**Response Format:**

```
{
    "success": true,
    "confirmed": "Final confirmed transcription chunk"
}
```

**Example:**

```
char final_response[32768];
int result = cactus_stream_transcribe_stop(stream, final_response, sizeof(final_response));
if (result >= 0) {
    printf("Final: %s\n", final_response);
}

// Or simply cleanup resources without response
cactus_stream_transcribe_stop(stream, NULL, 0);
```

### `cactus_diarize` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_diarize "Permanent link")

Runs speaker diarization on audio using the pyannote/segmentation-3.0 model. Supports both file-based and buffer-based audio input.

```
int cactus_diarize(
    cactus_model_t model,           // Model handle (must be PyAnnote model)
    const char* audio_file_path,    // Path to WAV file (16-bit PCM) - can be NULL if using pcm_buffer
    char* response_buffer,          // Buffer for response JSON
    size_t buffer_size,             // Size of response buffer
    const char* options_json,       // Optional JSON options (can be NULL)
    const uint8_t* pcm_buffer,      // Optional raw int16 PCM buffer (can be NULL if using file)
    size_t pcm_buffer_size          // Size of PCM buffer in bytes (must be even and >= 2)
);
```

**Returns:** Number of bytes written to response\_buffer on success, negative value on error

**Options (`options_json`):**
\| Field \| Type \| Default \| Description \|
\|---\|---\|---\|---\|
\| `step_ms` \| int \| 1000 \| Sliding window stride in milliseconds. Smaller = more overlap and smoother output, larger = faster. \|
\| `threshold` \| float \| none \| If set, zeroes out per-speaker scores below this value. Equivalent to `segmentation.threshold` in the Python pipeline. \|
\| `num_speakers` \| int \| none \| Keep only the N most active speakers (by total activity), zeroing out the rest. \|
\| `min_speakers` \| int \| none \| Lower bound on the number of active speakers to retain. \|
\| `max_speakers` \| int \| none \| Upper bound on the number of active speakers to retain. \|
\| `raw_powerset` \| bool \| false \| Return raw 7-class powerset scores instead of 3-speaker probabilities. When true, speaker filtering and thresholding are skipped. \|

**Note:** Exactly one of `audio_file_path` or `pcm_buffer` must be provided; passing both or neither returns -1. The file path must point to a 16-bit PCM WAV file. The `pcm_buffer` must contain 16-bit signed PCM samples at 16 kHz and `pcm_buffer_size` must be even and at least 2.

The model processes 10-second windows (160,000 samples at 16 kHz) with configurable step. Shorter input is zero-padded. Output scores are a flat array of T × num\_speakers float32 values in row-major order (index `f*num_speakers+s`), where T is the total number of output frames. When `raw_powerset` is false (default), num\_speakers is 3 and each value is the Hamming-weighted mean of per-speaker probabilities in \[0, 1\]. When `raw_powerset` is true, num\_speakers is 7 and values are raw powerset class scores.

**Response Format:**

```
{
    "success": true,
    "error": null,
    "num_speakers": 3,
    "scores": [0.0, 0.1, ...],
    "total_time_ms": 12.34,
    "ram_usage_mb": 256.0
}
```

**Example:**

```
cactus_model_t pyannote = cactus_init("../../weights/segmentation-3.0", NULL, false);

char response[1 << 20];
int result = cactus_diarize(pyannote, "audio.wav", response, sizeof(response), "{\"step_ms\":500}", NULL, 0);

if (result >= 0) {
    printf("Response: %s\n", response);
}
```

### `cactus_embed_speaker` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_embed_speaker "Permanent link")

Extracts a speaker embedding vector from audio using the WeSpeaker ResNet34-LM model. Supports both file-based and buffer-based audio input. Filter bank features are computed internally from raw audio.

```
int cactus_embed_speaker(
    cactus_model_t model,           // Model handle (must be WeSpeaker model)
    const char* audio_file_path,    // Path to WAV file (16-bit PCM) - can be NULL if using pcm_buffer
    char* response_buffer,          // Buffer for response JSON
    size_t buffer_size,             // Size of response buffer
    const char* options_json,       // Optional JSON options (can be NULL, reserved for future use)
    const uint8_t* pcm_buffer,      // Optional raw int16 PCM buffer (can be NULL if using file)
    size_t pcm_buffer_size,         // Size of PCM buffer in bytes (must be even and >= 2)
    const float* mask_weights,      // Optional per-frame mask weights for weighted embedding (can be NULL)
    size_t mask_num_frames          // Number of mask weight frames (0 if mask_weights is NULL)
);
```

**Returns:** Number of bytes written to response\_buffer on success, negative value on error

**Note:** Exactly one of `audio_file_path` or `pcm_buffer` must be provided; passing both or neither returns -1. The file path must point to a 16-bit PCM WAV file. The `pcm_buffer` must contain 16-bit signed PCM samples at 16 kHz and `pcm_buffer_size` must be even and at least 2. Output is a 256-dimensional speaker embedding. When `mask_weights` is provided, weighted stats pooling is used to extract a speaker-specific embedding — the mask weights are resampled to match the model's internal temporal resolution.

**Response Format:**

```
{
    "success": true,
    "error": null,
    "embedding": [0.123, -0.456, ...],
    "total_time_ms": 8.12,
    "ram_usage_mb": 128.0
}
```

**Example:**

```
cactus_model_t wespeaker = cactus_init("../../weights/wespeaker-voxceleb-resnet34-lm", NULL, false);

char response[1 << 16];
int result = cactus_embed_speaker(wespeaker, "audio.wav", response, sizeof(response), NULL, NULL, 0, NULL, 0);

if (result >= 0) {
    printf("Response: %s\n", response);
}
```

### `cactus_detect_language` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_detect_language "Permanent link")

Detects the spoken language in an audio file or PCM buffer.

```
int cactus_detect_language(
    cactus_model_t model,           // Model handle (must be Whisper model)
    const char* audio_file_path,    // Path to WAV file (16-bit PCM) - can be NULL if using pcm_buffer
    char* response_buffer,          // Buffer for response JSON
    size_t buffer_size,             // Size of response buffer
    const char* options_json,       // Optional options (can be NULL)
    const uint8_t* pcm_buffer,      // Optional raw PCM audio buffer (can be NULL if using file)
    size_t pcm_buffer_size          // Size of PCM buffer in bytes (must be even and >= 2)
);
```

**Returns:** Number of bytes written to response\_buffer on success, negative value on error

**Note:** Exactly one of `audio_file_path` or `pcm_buffer` must be provided; passing both or neither returns -1. The file path must point to a 16-bit PCM WAV file. The `pcm_buffer` must contain 16-bit signed PCM samples at 16 kHz and `pcm_buffer_size` must be even and at least 2. Only Whisper models are supported; passing any other model type returns -1.

**Options Format:**

```
{
    "use_vad": true
}
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `use_vad` | bool | true | Filter audio through VAD before language detection (requires model initialized with a VAD component) |

**Response Format:**

```
{
    "success": true,
    "error": null,
    "language": "en",
    "language_token": "<|en|>",
    "token_id": 50259,
    "confidence": 0.9812,
    "entropy": 0.0188,
    "total_time_ms": 234.56,
    "ram_usage_mb": 512.34
}
```

- `language`: ISO 639-1 language code, or `"unknown"` if detection failed
- `language_token`: Raw token text emitted by the model for the language (e.g. `"<|en|>"`)
- `token_id`: Vocabulary token ID of the language token
- `confidence`: Detection confidence (0.0–1.0), derived as `1.0 - entropy`
- `entropy`: Normalized entropy of the sampled token
- `total_time_ms`: Total detection time in milliseconds
- `ram_usage_mb`: Current process RAM usage

**Example:**

```
cactus_model_t whisper = cactus_init("../../weights/whisper-small", NULL, false);

char response[1024];
int result = cactus_detect_language(whisper, "audio.wav", response, sizeof(response), NULL, NULL, 0);
if (result >= 0) {
    printf("Detected language: %s\n", response);
}
```

### `cactus_vad` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_vad "Permanent link")

Detects speech segments in audio using Voice Activity Detection. Supports both file-based and buffer-based audio input.

```
int cactus_vad(
    cactus_model_t model,           // Model handle (must be VAD model)
    const char* audio_file_path,    // Path to WAV file (16-bit PCM) - can be NULL if using pcm_buffer
    char* response_buffer,          // Buffer for response JSON
    size_t buffer_size,             // Size of response buffer
    const char* options_json,       // Optional VAD options (can be NULL)
    const uint8_t* pcm_buffer,      // Optional raw PCM audio buffer (can be NULL if using file)
    size_t pcm_buffer_size          // Size of PCM buffer in bytes (must be even and >= 2)
);
```

**Returns:** Number of bytes written to response\_buffer on success, negative value on error

**Note:** Exactly one of `audio_file_path` or `pcm_buffer` must be provided; passing both or neither returns -1. The file path must point to a 16-bit PCM WAV file. The `pcm_buffer` must contain 16-bit signed PCM samples at 16 kHz and `pcm_buffer_size` must be even and at least 2.

**Options Format:**

```
{
    "threshold": 0.5,
    "neg_threshold": 0.0,
    "min_speech_duration_ms": 250,
    "max_speech_duration_s": 30.0,
    "min_silence_duration_ms": 100,
    "speech_pad_ms": 30,
    "window_size_samples": 512,
    "min_silence_at_max_speech": 98,
    "use_max_poss_sil_at_max_speech": true,
    "sampling_rate": 16000
}
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `threshold` | float | 0.5 | Speech probability threshold (0.0–1.0) |
| `neg_threshold` | float | 0.0 | Threshold below which a frame is considered non-speech; 0.0 means auto-compute as `max(threshold - 0.15, 0.01)` |
| `min_speech_duration_ms` | int | 250 | Minimum speech segment duration in milliseconds |
| `max_speech_duration_s` | float | infinity | Maximum speech segment duration in seconds |
| `min_silence_duration_ms` | int | 100 | Minimum silence duration to split segments |
| `speech_pad_ms` | int | 30 | Padding added to each end of a speech segment in milliseconds |
| `window_size_samples` | int | 512 | Window size for VAD processing |
| `min_silence_at_max_speech` | int | 98 | Minimum silence duration in milliseconds at which a segment may be split when max\_speech\_duration\_s is reached |
| `use_max_poss_sil_at_max_speech` | bool | true | Use maximum possible silence at max speech duration |
| `sampling_rate` | int | 16000 | Audio sampling rate in Hz |

**Response Format:**

```
{
    "success": true,
    "error": null,
    "segments": [\
        {"start": 0, "end": 16000},\
        {"start": 32000, "end": 48000}\
    ],
    "total_time_ms": 12.34,
    "ram_usage_mb": 45.67
}
```

- `segments`: Array of `{"start": int, "end": int}` objects, where values are sample indices (not seconds)

**Example:**

```
cactus_model_t vad = cactus_init("../../weights/silero-vad", NULL, false);

char response[4096];
int result = cactus_vad(vad, "audio.wav", response, sizeof(response), NULL, NULL, 0);

if (result >= 0) {
    printf("Response: %s\n", response);
}
```

### `cactus_embed` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_embed "Permanent link")

Generates text embeddings for semantic search, similarity, and RAG applications.

```
int cactus_embed(
    cactus_model_t model,        // Model handle
    const char* text,            // Text to embed
    float* embeddings_buffer,    // Buffer for embedding vector
    size_t buffer_size,          // Size of embeddings_buffer in bytes
    size_t* embedding_dim,       // Output: actual embedding dimensions
    bool normalize               // Whether to L2-normalize the output vector
);
```

**Returns:** Number of float elements written to embeddings\_buffer on success; -1 on invalid parameters, tokenization error, or other failure; -2 if `buffer_size` (in bytes) is smaller than `embedding_dim * sizeof(float)`

**Example:**

```
const char* text = "The quick brown fox jumps over the lazy dog";
float embeddings[2048];
size_t actual_dim = 0;

int result = cactus_embed(model, text, embeddings, sizeof(embeddings), &actual_dim, true);
if (result >= 0) {
    printf("Generated %zu-dimensional embedding\n", actual_dim);
}
```

**Note:** Set `normalize` to `true` for cosine similarity comparisons (recommended for most use cases).

### `cactus_image_embed` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_image_embed "Permanent link")

Generates embeddings for images, useful for multimodal retrieval tasks.

```
int cactus_image_embed(
    cactus_model_t model,        // Model handle (must support vision)
    const char* image_path,      // Path to image file
    float* embeddings_buffer,    // Buffer for embedding vector
    size_t buffer_size,          // Size of embeddings_buffer in bytes
    size_t* embedding_dim        // Output: actual embedding dimensions
);
```

**Returns:** Number of float elements written to embeddings\_buffer on success; -1 on invalid parameters or embedding failure; -2 if `buffer_size` (in bytes) is smaller than `embedding_dim * sizeof(float)`

**Example:**

```
float image_embeddings[1024];
size_t dim = 0;

int result = cactus_image_embed(model, "photo.jpg", image_embeddings, sizeof(image_embeddings), &dim);
if (result >= 0) {
    printf("Image embedding dimension: %zu\n", dim);
}
```

### `cactus_audio_embed` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_audio_embed "Permanent link")

Generates embeddings for audio files, useful for audio retrieval and classification.

```
int cactus_audio_embed(
    cactus_model_t model,        // Model handle (must support audio)
    const char* audio_path,      // Path to audio file
    float* embeddings_buffer,    // Buffer for embedding vector
    size_t buffer_size,          // Size of embeddings_buffer in bytes
    size_t* embedding_dim        // Output: actual embedding dimensions
);
```

**Returns:** Number of float elements written to embeddings\_buffer on success; -1 on invalid parameters or embedding failure; -2 if `buffer_size` (in bytes) is smaller than `embedding_dim * sizeof(float)`

**Example:**

```
float audio_embeddings[768];
size_t dim = 0;

int result = cactus_audio_embed(model, "speech.wav", audio_embeddings, sizeof(audio_embeddings), &dim);
```

### `cactus_stop` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_stop "Permanent link")

Stops ongoing generation. Useful for implementing early stopping based on custom logic.

```
void cactus_stop(cactus_model_t model);
```

**Example with Controlled Generation:**

```
struct ControlData {
    cactus_model_t model;
    int token_count;
    int max_tokens;
};

void control_callback(const char* token, uint32_t token_id, void* user_data) {
    struct ControlData* data = (struct ControlData*)user_data;
    printf("%s", token);
    data->token_count++;

    // Stop after reaching limit
    if (data->token_count >= data->max_tokens) {
        cactus_stop(data->model);
    }
}

struct ControlData control = {model, 0, 50};
cactus_complete(model, messages, response, sizeof(response),
                NULL, NULL, control_callback, &control, NULL, 0);
```

### `cactus_reset` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_reset "Permanent link")

Resets the model's internal state, clearing KV cache and any cached context.

```
void cactus_reset(cactus_model_t model);
```

**Use Cases:**
\- Starting a new conversation
\- Clearing context between unrelated requests
\- Recovering from errors
\- Freeing memory after long conversations

### `cactus_rag_query` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_rag_query "Permanent link")

Queries the RAG corpus and returns relevant text chunks. Requires model to be initialized with a corpus directory.

```
int cactus_rag_query(
    cactus_model_t model,        // Model handle (must have corpus_dir set)
    const char* query,           // Query text
    char* response_buffer,       // Buffer for response JSON
    size_t buffer_size,          // Size of response buffer
    size_t top_k                 // Number of chunks to retrieve
);
```

**Returns:** Number of bytes written to response\_buffer on success; 0 when the query cannot be executed (no corpus index, no tokenizer, empty query, or dimension mismatch) — response\_buffer contains `{"chunks":[],"error":"..."}` in those cases; also 0 when the query executes but returns no results — response\_buffer contains `{"chunks":[]}` with no `error` field; -1 on error (invalid params, buffer too small, or exception)

**Response Format:**

```
{
    "chunks": [\
        {"score": 0.85, "source": "document.txt", "content": "Relevant chunk 1..."},\
        {"score": 0.72, "source": "document.txt", "content": "Relevant chunk 2..."}\
    ]
}
```

When the query cannot be executed (no corpus index, no tokenizer, empty query, or dimension mismatch), `chunks` is empty and an `error` field is present:

```
{
    "chunks": [],
    "error": "No corpus index loaded"
}
```

**Example:**

```
// Initialize model with corpus
cactus_model_t model = cactus_init("path/to/model", "./documents", true);

// Query for relevant chunks
char response[65536];
int result = cactus_rag_query(model, "What is machine learning?",
                               response, sizeof(response), 5);
if (result >= 0) {
    printf("Retrieved chunks: %s\n", response);
}
```

### `cactus_destroy` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_destroy "Permanent link")

Releases all resources associated with the model.

```
void cactus_destroy(cactus_model_t model);
```

**Important:** Always call this when done with a model to prevent memory leaks.

## Utility Functions [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#utility-functions "Permanent link")

### `cactus_get_last_error` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_get_last_error "Permanent link")

Returns the last error message from the Cactus engine.

```
const char* cactus_get_last_error(void);
```

**Returns:** Error message string (never NULL; empty string if no error)

**Example:**

```
cactus_model_t model = cactus_init("invalid/path", NULL, false);
if (!model) {
    const char* error = cactus_get_last_error();
    fprintf(stderr, "Error: %s\n", error);
}
```

## Vector Index APIs [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#vector-index-apis "Permanent link")

The vector index APIs provide persistent storage and retrieval of embeddings for RAG (Retrieval-Augmented Generation) applications.

### `cactus_index_init` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_index_init "Permanent link")

Initializes or opens a vector index from disk.

```
cactus_index_t cactus_index_init(
    const char* index_dir,       // Path to index directory
    size_t embedding_dim         // Dimension of embeddings to store
);
```

**Returns:** Index handle on success, NULL on failure

**Example:**

```
cactus_index_t index = cactus_index_init("./my_index", 768);
if (!index) {
    fprintf(stderr, "Failed to initialize index\n");
    return -1;
}
```

### `cactus_index_add` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_index_add "Permanent link")

Adds documents with their embeddings to the index.

```
int cactus_index_add(
    cactus_index_t index,        // Index handle
    const int* ids,              // Array of document IDs
    const char** documents,      // Array of document texts
    const char** metadatas,      // Array of metadata JSON strings (can be NULL)
    const float** embeddings,    // Array of embedding vectors
    size_t count,                // Number of documents to add
    size_t embedding_dim         // Dimension of each embedding
);
```

**Returns:** 0 on success, negative value on error

**Example:**

```
int ids[] = {1, 2, 3};
const char* docs[] = {"Hello world", "Foo bar", "Test document"};
const char* metas[] = {"{\"source\":\"a\"}", "{\"source\":\"b\"}", NULL};

float emb1[768], emb2[768], emb3[768];
const float* embeddings[] = {emb1, emb2, emb3};

int result = cactus_index_add(index, ids, docs, metas, embeddings, 3, 768);
```

### `cactus_index_delete` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_index_delete "Permanent link")

Deletes documents from the index by ID.

```
int cactus_index_delete(
    cactus_index_t index,        // Index handle
    const int* ids,              // Array of document IDs to delete
    size_t ids_count             // Number of IDs
);
```

**Returns:** 0 on success, negative value on error

**Example:**

```
int ids_to_delete[] = {1, 3};
cactus_index_delete(index, ids_to_delete, 2);
```

### `cactus_index_get` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_index_get "Permanent link")

Retrieves documents by their IDs.

```
int cactus_index_get(
    cactus_index_t index,        // Index handle
    const int* ids,              // Array of document IDs to retrieve
    size_t ids_count,            // Number of IDs
    char** document_buffers,     // Output: document text buffers
    size_t* document_buffer_sizes,  // Sizes of document buffers (in bytes)
    char** metadata_buffers,     // Output: metadata JSON buffers
    size_t* metadata_buffer_sizes,  // Sizes of metadata buffers (in bytes)
    float** embedding_buffers,   // Output: embedding buffers
    size_t* embedding_buffer_sizes  // Sizes of embedding buffers (in float elements, not bytes)
);
```

**Returns:** 0 on success, negative value on error

### `cactus_index_query` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_index_query "Permanent link")

Queries the index for similar documents using embedding vectors.

```
int cactus_index_query(
    cactus_index_t index,        // Index handle
    const float** embeddings,    // Array of query embeddings
    size_t embeddings_count,     // Number of query embeddings
    size_t embedding_dim,        // Dimension of each embedding
    const char* options_json,    // Query options (e.g., {"top_k": 10, "score_threshold": 0.5})
    int** id_buffers,            // Output: arrays of result IDs
    size_t* id_buffer_sizes,     // In: capacity of each id_buffer; Out: actual result count written
    float** score_buffers,       // Output: arrays of similarity scores
    size_t* score_buffer_sizes   // In: capacity of each score_buffer; Out: actual result count written
);
```

**Returns:** 0 on success, negative value on error

**Options JSON fields:**

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `top_k` | int | 10 | Maximum number of results to return per query |
| `score_threshold` | float | -1.0 | Minimum similarity score threshold; results below this are excluded (-1.0 disables filtering) |

**Example:**

```
float query_emb[768];
size_t dim;
cactus_embed(model, "search query", query_emb, sizeof(query_emb), &dim, true);

const float* queries[] = {query_emb};
int result_ids[10];
float result_scores[10];
int* id_bufs[] = {result_ids};
float* score_bufs[] = {result_scores};
size_t id_sizes[] = {10};
size_t score_sizes[] = {10};

cactus_index_query(index, queries, 1, 768, "{\"top_k\": 10}",
                   id_bufs, id_sizes, score_bufs, score_sizes);

// id_sizes[0] is updated to the actual number of results returned
for (size_t i = 0; i < id_sizes[0]; i++) {
    printf("ID: %d, Score: %.4f\n", result_ids[i], result_scores[i]);
}
```

### `cactus_index_compact` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_index_compact "Permanent link")

Compacts the index to optimize storage and query performance.

```
int cactus_index_compact(cactus_index_t index);
```

**Returns:** 0 on success, negative value on error

**Example:**

```
cactus_index_compact(index);
```

### `cactus_index_destroy` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_index_destroy "Permanent link")

Releases all resources associated with the index.

```
void cactus_index_destroy(cactus_index_t index);
```

**Important:** Always call this when done with an index to ensure data is persisted.

### Complete RAG Example [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#complete-rag-example "Permanent link")

```
#include "cactus_ffi.h"

int main() {
    cactus_model_t embed_model = cactus_init("path/to/embed-model", NULL, false);
    cactus_index_t index = cactus_index_init("./rag_index", 768);

    const char* docs[] = {
        "The capital of France is Paris.",
        "Python is a programming language.",
        "The Earth orbits the Sun."
    };
    int ids[] = {1, 2, 3};
    float emb1[768], emb2[768], emb3[768];
    size_t dim;

    cactus_embed(embed_model, docs[0], emb1, sizeof(emb1), &dim, true);
    cactus_embed(embed_model, docs[1], emb2, sizeof(emb2), &dim, true);
    cactus_embed(embed_model, docs[2], emb3, sizeof(emb3), &dim, true);

    const float* embeddings[] = {emb1, emb2, emb3};
    cactus_index_add(index, ids, docs, NULL, embeddings, 3, 768);

    float query_emb[768];
    cactus_embed(embed_model, "What is the capital of France?", query_emb, sizeof(query_emb), &dim, true);

    const float* queries[] = {query_emb};
    int result_ids[3];
    float result_scores[3];
    int* id_bufs[] = {result_ids};
    float* score_bufs[] = {result_scores};
    size_t id_sizes[] = {3};
    size_t score_sizes[] = {3};

    cactus_index_query(index, queries, 1, 768, "{\"top_k\": 3}",
                       id_bufs, id_sizes, score_bufs, score_sizes);

    printf("Top result ID: %d (score: %.4f)\n", result_ids[0], result_scores[0]);

    cactus_index_destroy(index);
    cactus_destroy(embed_model);
    return 0;
}
```

## Complete Examples [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#complete-examples "Permanent link")

### Basic Conversation [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#basic-conversation "Permanent link")

```
#include "cactus_ffi.h"
#include <stdio.h>

int main() {
    cactus_model_t model = cactus_init("path/to/model", NULL, false);
    if (!model) return -1;

    const char* messages =
        "[{\"role\": \"system\", \"content\": \"You are a helpful assistant.\"},"\
        " {\"role\": \"user\", \"content\": \"Hello!\"},"\
        " {\"role\": \"assistant\", \"content\": \"Hello! How can I help you today?\"},"\
        " {\"role\": \"user\", \"content\": \"What's 2+2?\"}]";

    char response[4096];
    int result = cactus_complete(model, messages, response,
                                 sizeof(response), NULL, NULL, NULL, NULL, NULL, 0);
    if (result >= 0) {
        printf("Response: %s\n", response);
    }

    cactus_destroy(model);
    return 0;
}
```

### Vision-Language Model (VLM) [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#vision-language-model-vlm "Permanent link")

```
#include "cactus_ffi.h"

int main() {
    cactus_model_t vlm = cactus_init("path/to/lfm2-vlm", NULL, false);
    if (!vlm) return -1;

    const char* messages =
        "[{\"role\": \"user\","\
        "  \"content\": \"What do you see in this image?\","\
        "  \"images\": [\"/path/to/photo.jpg\"]}]";

    char response[8192];
    int result = cactus_complete(vlm, messages, response, sizeof(response),
                                 NULL, NULL, NULL, NULL, NULL, 0);
    if (result >= 0) {
        printf("%s\n", response);
    }

    cactus_destroy(vlm);
    return 0;
}
```

### Tool Calling [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#tool-calling "Permanent link")

```
const char* tools =
    "[{\"function\": {"\
    "    \"name\": \"get_weather\","\
    "    \"description\": \"Get weather for a location\","\
    "    \"parameters\": {"\
    "        \"type\": \"object\","\
    "        \"properties\": {"\
    "            \"location\": {\"type\": \"string\", \"description\": \"City, State, Country\"}"\
    "        },"\
    "        \"required\": [\"location\"]"\
    "    }"\
    "}}]";

const char* messages = "[{\"role\": \"user\", \"content\": \"What's the weather in Paris?\"}]";

char response[4096];
int result = cactus_complete(model, messages, response, sizeof(response),
                             NULL, tools, NULL, NULL, NULL, 0);
printf("Response: %s\n", response);
```

### Computing Similarity with Embeddings [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#computing-similarity-with-embeddings "Permanent link")

```
float compute_cosine_similarity(cactus_model_t model, const char* text1, const char* text2) {
    float embeddings1[2048], embeddings2[2048];
    size_t dim1, dim2;

    cactus_embed(model, text1, embeddings1, sizeof(embeddings1), &dim1, true);
    cactus_embed(model, text2, embeddings2, sizeof(embeddings2), &dim2, true);

    // with normalized embeddings, cosine similarity = dot product
    float dot_product = 0.0f;
    for (size_t i = 0; i < dim1; i++) {
        dot_product += embeddings1[i] * embeddings2[i];
    }
    return dot_product;
}

float similarity = compute_cosine_similarity(embed_model,
    "The cat sat on the mat", "A feline rested on the rug");
printf("Similarity: %.4f\n", similarity);
```

### Audio Transcription with Whisper [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#audio-transcription-with-whisper "Permanent link")

```
#include "cactus_ffi.h"
#include <stdio.h>

void transcription_callback(const char* token, uint32_t token_id, void* user_data) {
    printf("%s", token);
    fflush(stdout);
}

int main() {
    cactus_model_t whisper = cactus_init("path/to/whisper-small", NULL, false);
    if (!whisper) return -1;

    char response[32768];
    int result = cactus_transcribe(whisper, "meeting.wav", NULL,
                                    response, sizeof(response), NULL,
                                    transcription_callback, NULL, NULL, 0);
    printf("\n\nFull response: %s\n", response);

    cactus_destroy(whisper);
    return 0;
}
```

### Multimodal Retrieval [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#multimodal-retrieval "Permanent link")

```
#include "cactus_ffi.h"
#include <math.h>

int find_similar_image(cactus_model_t model, const char* query,
                       const char** image_paths, int num_images) {
    float query_embed[1024];
    size_t query_dim;
    cactus_embed(model, query, query_embed, sizeof(query_embed), &query_dim, true);

    float best_score = -1.0f;
    int best_idx = -1;

    for (int i = 0; i < num_images; i++) {
        float img_embed[1024];
        size_t img_dim;
        cactus_image_embed(model, image_paths[i], img_embed, sizeof(img_embed), &img_dim);

        float dot = 0, norm_q = 0, norm_i = 0;
        for (size_t j = 0; j < query_dim; j++) {
            dot += query_embed[j] * img_embed[j];
            norm_q += query_embed[j] * query_embed[j];
            norm_i += img_embed[j] * img_embed[j];
        }
        float score = dot / (sqrtf(norm_q) * sqrtf(norm_i));

        if (score > best_score) {
            best_score = score;
            best_idx = i;
        }
    }
    return best_idx;
}
```

## Supported Model Types [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#supported-model-types "Permanent link")

| Model Type | Text | Vision | Audio | Embeddings | Description |
| --- | --- | --- | --- | --- | --- |
| Qwen | ✓ | ✓ | - | ✓ | Qwen3/Qwen3.5 language and vision models |
| Gemma4 | ✓ | ✓ | ✓ | ✓ | Google Gemma 4 multimodal (E2B, E4B) with Apple NPU |
| Gemma | ✓ | - | - | - | Google Gemma 3 / Gemma 3n models |
| LFM2 | ✓ | ✓ | - | ✓ | Liquid Foundation Models (incl. VL and MoE) |
| Nomic | - | - | - | ✓ | Nomic embedding models |
| Whisper | - | - | ✓ | ✓ | OpenAI Whisper transcription |
| Moonshine | - | - | ✓ | ✓ | UsefulSensors Moonshine transcription |
| Parakeet | - | - | ✓ | ✓ | Nvidia Parakeet CTC/TDT transcription |
| PyAnnote | - | - | ✓ | - | Speaker diarization (segmentation-3.0) |
| WeSpeaker | - | - | ✓ | - | Speaker embedding (ResNet34-LM) |
| Silero VAD | - | - | ✓ | - | Voice activity detection |

## Environment Variables [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#environment-variables "Permanent link")

| Variable | Default | Description |
| --- | --- | --- |
| `CACTUS_KV_WINDOW_SIZE` | 512 | Sliding window size for KV cache |
| `CACTUS_KV_SINK_SIZE` | 4 | Number of attention sink tokens to preserve |

**Example:**

```
export CACTUS_KV_WINDOW_SIZE=1024
export CACTUS_KV_SINK_SIZE=8
./my_app
```

## Best Practices [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#best-practices "Permanent link")

1. **Always Check Return Values**: Functions return negative values on error
2. **Buffer Sizes**: Use large response buffers (8192+ bytes recommended)
3. **Memory Management**: Always call `cactus_destroy()` when done
4. **Thread Safety**: Each model instance should be used from a single thread
5. **Context Management**: Use `cactus_reset()` between unrelated conversations
6. **Streaming**: Implement callbacks for better user experience with long generations
7. **Reuse Models**: Initialize once, use multiple times for efficiency

## Error Handling [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#error-handling "Permanent link")

Most functions return:
\- Positive values or 0 on success
\- Negative values on error

Common error scenarios:
\- Invalid model path
\- Insufficient buffer size
\- Malformed JSON input
\- Unsupported operation for model type
\- Out of memory

## Performance Tips [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#performance-tips "Permanent link")

1. **Reuse Model Instances**: Initialize once, use multiple times
2. **Streaming for UX**: Use callbacks for responsive user interfaces
3. **Early Stopping**: Use `cactus_stop()` to avoid unnecessary generation
4. **Batch Embeddings**: When possible, process multiple texts in sequence without resetting
5. **KV Cache Tuning**: Adjust `CACTUS_KV_WINDOW_SIZE` based on your context needs

## Logging [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#logging "Permanent link")

### `cactus_log_set_level` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_log_set_level "Permanent link")

Sets the minimum log level. Messages below this level are suppressed.

```
void cactus_log_set_level(int level);
// level: 0=DEBUG, 1=INFO, 2=WARN (default), 3=ERROR, 4=NONE
```

### `cactus_log_set_callback` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_log_set_callback "Permanent link")

Installs a callback to receive log messages. Pass NULL to remove the callback.

```
typedef void (*cactus_log_callback_t)(int level, const char* component, const char* message, void* user_data);

void cactus_log_set_callback(cactus_log_callback_t callback, void* user_data);
```

**Example:**

```
void my_log(int level, const char* component, const char* message, void* user_data) {
    printf("[%d] %s: %s\n", level, component, message);
}

cactus_log_set_level(1); // INFO and above
cactus_log_set_callback(my_log, NULL);
```

## Telemetry [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#telemetry "Permanent link")

These functions configure anonymous usage telemetry sent to Cactus Compute. Telemetry is opt-out and contains no user data.

### `cactus_set_telemetry_environment` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_set_telemetry_environment "Permanent link")

Identifies the SDK framework and cache directory.

```
void cactus_set_telemetry_environment(const char* framework, const char* cache_location, const char* version);
```

### `cactus_set_app_id` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_set_app_id "Permanent link")

Associates telemetry events with an application identifier.

```
void cactus_set_app_id(const char* app_id);
```

### `cactus_telemetry_flush` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_telemetry_flush "Permanent link")

Flushes pending telemetry events.

```
void cactus_telemetry_flush(void);
```

### `cactus_telemetry_shutdown` [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#cactus_telemetry_shutdown "Permanent link")

Flushes and shuts down the telemetry subsystem. Call before process exit.

```
void cactus_telemetry_shutdown(void);
```

## See Also [¶](https://docs.cactuscompute.com/latest/docs/cactus_engine/\#see-also "Permanent link")

- [Cactus Graph API](https://docs.cactuscompute.com/latest/docs/cactus_graph/) — Low-level computational graph for custom tensor operations
- [Cactus Index API](https://docs.cactuscompute.com/latest/docs/cactus_index/) — On-device vector database for RAG applications
- [Fine-tuning Guide](https://docs.cactuscompute.com/latest/docs/finetuning/) — Deploy Unsloth LoRA fine-tunes to mobile
- [Runtime Compatibility](https://docs.cactuscompute.com/latest/docs/compatibility/) — Weight versioning across releases
- [Python SDK](https://docs.cactuscompute.com/latest/python/) — Python bindings for the Engine API
- [Swift SDK](https://docs.cactuscompute.com/latest/apple/) — Swift bindings for iOS and macOS
- [Kotlin/Android SDK](https://docs.cactuscompute.com/latest/android/) — Kotlin Multiplatform bindings
- [Flutter SDK](https://docs.cactuscompute.com/latest/flutter/) — Dart FFI bindings for mobile apps
- [Rust SDK](https://docs.cactuscompute.com/latest/rust/) — Rust FFI bindings via bindgen

Back to top
[Previous\\
\\
\\
Rust](https://docs.cactuscompute.com/latest/rust/) [Next\\
\\
\\
Graph API](https://docs.cactuscompute.com/latest/docs/cactus_graph/)



Made with
[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)

[github.com](https://github.com/cactus-compute/cactus "github.com")[www.reddit.com](https://www.reddit.com/r/cactuscompute/ "www.reddit.com")