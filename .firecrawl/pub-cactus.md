[![](https://pub.dev/static/hash-ilufue8n/img/pub-dev-logo.svg)](https://pub.dev/)

Sign in

Help

### pub.dev

[Searching for packages](https://pub.dev/help/search) [Package scoring and pub points](https://pub.dev/help/scoring)

### Flutter

[Using packages](https://flutter.dev/using-packages/) [Developing packages and plugins](https://flutter.dev/developing-packages/) [Publishing a package](https://dart.dev/tools/pub/publishing)

### Dart

[Using packages](https://dart.dev/guides/packages) [Publishing a package](https://dart.dev/tools/pub/publishing)

### pub.dev ![toggle folding of the section](https://pub.dev/static/hash-ilufue8n/img/nav-mobile-foldable-icon.svg)

[Searching for packages](https://pub.dev/help/search) [Package scoring and pub points](https://pub.dev/help/scoring)

### Flutter ![toggle folding of the section](https://pub.dev/static/hash-ilufue8n/img/nav-mobile-foldable-icon.svg)

[Using packages](https://flutter.dev/using-packages/) [Developing packages and plugins](https://flutter.dev/developing-packages/) [Publishing a package](https://dart.dev/tools/pub/publishing)

### Dart ![toggle folding of the section](https://pub.dev/static/hash-ilufue8n/img/nav-mobile-foldable-icon.svg)

[Using packages](https://dart.dev/guides/packages) [Publishing a package](https://dart.dev/tools/pub/publishing)

# cactus 1.3.0 ![copy "cactus: ^1.3.0" to clipboard](https://pub.dev/static/hash-ilufue8n/img/content-copy-icon.svg) cactus: ^1.3.0 copied to clipboard

Published [4 months ago](https://pub.dev/packages/cactus "Dec 19, 2025") • [![verified publisher](https://pub.dev/static/hash-ilufue8n/img/material-icon-verified.svg)cactuscompute.com](https://pub.dev/publishers/cactuscompute.com)

SDK [Flutter](https://pub.dev/packages?q=sdk%3Aflutter "Packages compatible with Flutter SDK")

Platform [Android](https://pub.dev/packages?q=platform%3Aandroid "Packages compatible with Android platform") [iOS](https://pub.dev/packages?q=platform%3Aios "Packages compatible with iOS platform") [macOS](https://pub.dev/packages?q=platform%3Amacos "Packages compatible with macOS platform")

![liked status: active](https://pub.dev/static/hash-ilufue8n/img/like-active.svg)![liked status: inactive](https://pub.dev/static/hash-ilufue8n/img/like-inactive.svg)23

→

### Metadata

Build AI apps with Cactus

More...

- Readme
- [Changelog](https://pub.dev/packages/cactus/changelog)
- [Example](https://pub.dev/packages/cactus/example)
- [Installing](https://pub.dev/packages/cactus/install)
- [Versions](https://pub.dev/packages/cactus/versions)
- [Scores](https://pub.dev/packages/cactus/score)

# Cactus Flutter Plugin [\#](https://pub.dev/packages/cactus\#cactus-flutter-plugin)

![Cactus Logo](https://external-images.pub.dev/j3NzhY5l%2Fmw454gOWmOvc36a%2Bpnp4lIeaW9b5uHLzis%3D/1778716800000/https%3A%2F%2Fgithub.com%2Fcactus-compute%2Fcactus-flutter%2Fblob%2Fmain%2Fassets%2Flogo.png%3Fraw%3Dtrue)

Official Flutter plugin for Cactus, a framework for deploying LLM models, speech-to-text, and RAG capabilities locally in your app. Requires iOS 12.0+, Android API 24+.

## Resources [\#](https://pub.dev/packages/cactus\#resources)

[![cactus](https://external-images.pub.dev/uUfMgjq4FdDFx16P0esvSILCojc4AWAV1Z48kZUjrO4%3D/1778716800000/https%3A%2F%2Fimg.shields.io%2Fbadge%2Fcactus-000000%3Flogo%3Dgithub%26logoColor%3Dwhite)](https://github.com/cactus-compute/cactus)[![HuggingFace](https://external-images.pub.dev/VweZiarw6qrWvP68dhHJ5PC%2B9OwD51%2BJ9iY2W8sZY3E%3D/1778716800000/https%3A%2F%2Fimg.shields.io%2Fbadge%2FHuggingFace-FFD21E%3Flogo%3Dhuggingface%26logoColor%3Dblack)](https://huggingface.co/Cactus-Compute/models?sort=downloads)[![Discord](https://external-images.pub.dev/5ceCCXrIXn%2BFyccuEIee9KqpJVyiYMPZm80BSkgnFi0%3D/1778716800000/https%3A%2F%2Fimg.shields.io%2Fbadge%2FDiscord-5865F2%3Flogo%3Ddiscord%26logoColor%3Dwhite)](https://discord.gg/bNurx3AXTJ)[![Documentation](https://external-images.pub.dev/qiyKNmLgkvyPHaEqgJFJAT7QKXZAKLTTuJZlbMm60CE%3D/1778716800000/https%3A%2F%2Fimg.shields.io%2Fbadge%2FDocumentation-4285F4%3Flogo%3Dgoogledocs%26logoColor%3Dwhite)](https://cactuscompute.com/docs)

## Installation [\#](https://pub.dev/packages/cactus\#installation)

Execute the following command in your project terminal:

```bash
flutter pub add cactus
```

copied to clipboard

## Getting Started [\#](https://pub.dev/packages/cactus\#getting-started)

### Configuration (Optional) [\#](https://pub.dev/packages/cactus\#configuration-optional)

Telemetry is enabled by default to help improve the SDK. You can easily disable it:

```dart
import 'package:cactus/cactus.dart';

// Disable telemetry
CactusConfig.isTelemetryEnabled = false;
```

copied to clipboard

You can also optionally set a telemetry token to track usage across your organization:

```dart
CactusConfig.setTelemetryToken("your-token-here");
```

copied to clipboard

To enable NPU acceleration (requires a Pro key):

```dart
CactusConfig.setProKey("your-pro-key-here"); // contact founders@cactuscompute.com to get your token!
```

copied to clipboard

## Language Model (LLM) [\#](https://pub.dev/packages/cactus\#language-model-llm)

The `CactusLM` class provides text completion capabilities with high-performance local inference.

### Basic Usage [\#](https://pub.dev/packages/cactus\#basic-usage)

```dart
import 'package:cactus/cactus.dart';

Future<void> basicExample() async {
  final lm = CactusLM();

  try {
    // Download a model by slug (e.g., "qwen3-0.6", "gemma3-270m")
    // If no model is specified, it defaults to "qwen3-0.6"
    await lm.downloadModel(
      model: "qwen3-0.6", // Optional: specify model slug
      downloadProcessCallback: (progress, status, isError) {
        if (isError) {
          print("Download error: $status");
        } else {
          print("$status ${progress != null ? '(${progress * 100}%)' : ''}");
        }
      },
    );

    // Initialize the model
    await lm.initializeModel();

    // Generate completion with default parameters
    final result = await lm.generateCompletion(
      messages: [\
        ChatMessage(content: "Hello, how are you?", role: "user"),\
      ],
    );

    if (result.success) {
      print("Response: ${result.response}");
      print("Tokens per second: ${result.tokensPerSecond}");
      print("Time to first token: ${result.timeToFirstTokenMs}ms");
    }
  } finally {
    // Clean up
    lm.unload();
  }
}
```

copied to clipboard

### Streaming Completions [\#](https://pub.dev/packages/cactus\#streaming-completions)

```dart
Future<void> streamingExample() async {
  final lm = CactusLM();

  // Download model (defaults to "qwen3-0.6" if model parameter is omitted)
  await lm.downloadModel(model: "qwen3-0.6");
  await lm.initializeModel();

  // Get the streaming response with default parameters
  final streamedResult = await lm.generateCompletionStream(
    messages: [ChatMessage(content: "Tell me a story", role: "user")],
  );

  // Process streaming output
  await for (final chunk in streamedResult.stream) {
    print(chunk);
  }

  // You can also get the full completion result after the stream is done
  final finalResult = await streamedResult.result;
  if (finalResult.success) {
    print("Final response: ${finalResult.response}");
    print("Tokens per second: ${finalResult.tokensPerSecond}");
  }

  lm.unload();
}
```

copied to clipboard

### Function Calling [\#](https://pub.dev/packages/cactus\#function-calling)

```dart
Future<void> functionCallingExample() async {
  final lm = CactusLM();

  await lm.downloadModel(model: "qwen3-0.6");
  await lm.initializeModel();

  final tools = [\
    CactusTool(\
      name: "get_weather",\
      description: "Get current weather for a location",\
      parameters: ToolParametersSchema(\
        properties: {\
          'location': ToolParameter(type: 'string', description: 'City name', required: true),\
        },\
      ),\
    ),\
  ];

  final result = await lm.generateCompletion(
    messages: [ChatMessage(content: "What's the weather in New York?", role: "user")],
    params: CactusCompletionParams(
      tools: tools
    )
  );

  if (result.success) {
    print("Response: ${result.response}");
    print("Tools: ${result.toolCalls}");
  }

  lm.unload();
}
```

copied to clipboard

### Tool Filtering [\#](https://pub.dev/packages/cactus\#tool-filtering)

When working with many tools, you can use tool filtering to automatically select the most relevant tools for each query. This reduces context size and improves model performance. Tool filtering is **enabled by default** and works automatically when you provide tools to `generateCompletion()` or `generateCompletionStream()`.

**How it works:**

- The `ToolFilterService` extracts the last user message from the conversation
- It scores each tool based on relevance to the query
- Only the most relevant tools (above the similarity threshold) are passed to the model
- If no tools pass the threshold, all tools are used (up to `maxTools` limit)

**Available Strategies:**

- **Simple (default)**: Fast keyword-based matching with fuzzy scoring
- **Semantic**: Uses embeddings for intent understanding (slower but more accurate)

```dart
import 'package:cactus/cactus.dart';
import 'package:cactus/services/tool_filter.dart';

Future<void> toolFilteringExample() async {
  // Configure tool filtering via constructor (optional)
  final lm = CactusLM(
    enableToolFiltering: true,  // default: true
    toolFilterConfig: ToolFilterConfig.simple(maxTools: 3),  // default config if not specified
  );
  await lm.downloadModel(model: "qwen3-0.6");
  await lm.initializeModel();

  // Define multiple tools
  final tools = [\
    CactusTool(\
      name: "get_weather",\
      description: "Get current weather for a location",\
      parameters: ToolParametersSchema(\
        properties: {\
          'location': ToolParameter(type: 'string', description: 'City name', required: true),\
        },\
      ),\
    ),\
    CactusTool(\
      name: "get_stock_price",\
      description: "Get current stock price for a company",\
      parameters: ToolParametersSchema(\
        properties: {\
          'symbol': ToolParameter(type: 'string', description: 'Stock symbol', required: true),\
        },\
      ),\
    ),\
    CactusTool(\
      name: "send_email",\
      description: "Send an email to someone",\
      parameters: ToolParametersSchema(\
        properties: {\
          'to': ToolParameter(type: 'string', description: 'Email address', required: true),\
          'subject': ToolParameter(type: 'string', description: 'Email subject', required: true),\
          'body': ToolParameter(type: 'string', description: 'Email body', required: true),\
        },\
      ),\
    ),\
  ];

  // Tool filtering happens automatically!
  // The ToolFilterService will analyze the query "What's the weather in Paris?"
  // and automatically select only the most relevant tool(s) (e.g., get_weather)
  final result = await lm.generateCompletion(
    messages: [ChatMessage(content: "What's the weather in Paris?", role: "user")],
    params: CactusCompletionParams(
      tools: tools
    )
  );

  if (result.success) {
    print("Response: ${result.response}");
    print("Tool calls: ${result.toolCalls}");
  }

  lm.unload();
}
```

copied to clipboard

**Note:** When tool filtering is active, you'll see debug output like:

```yaml
Tool filtering: 3 -> 1 tools
Filtered tools: get_weather
```

copied to clipboard

### Hybrid Completion (Cloud Fallback) [\#](https://pub.dev/packages/cactus\#hybrid-completion-cloud-fallback)

The `CactusLM` supports a `hybrid` completion mode that falls back to a cloud-based LLM provider (OpenRouter) if local inference fails or is not available. This ensures reliability and provides a seamless experience.

To use hybrid mode:

1. Set `completionMode` to `CompletionMode.hybrid` in `CactusCompletionParams`.
2. Provide a `cactusToken` in `CactusCompletionParams`.

```dart
import 'package:cactus/cactus.dart';

Future<void> hybridCompletionExample() async {
  final lm = CactusLM();

  // No model download or initialization needed if you only want to use cloud

  final result = await lm.generateCompletion(
    messages: [ChatMessage(content: "What's the weather in New York?", role: "user")],
    params: CactusCompletionParams(
      completionMode: CompletionMode.hybrid,
      cactusToken: "YOUR_CACTUS_TOKEN",
    ),
  );

  if (result.success) {
    print("Response: ${result.response}");
  }

  lm.unload();
}
```

copied to clipboard

### Fetching Available Models [\#](https://pub.dev/packages/cactus\#fetching-available-models)

```dart
Future<void> fetchModelsExample() async {
  final lm = CactusLM();

  // Get list of available models with caching
  final models = await lm.getModels();

  for (final model in models) {
    print("Model: ${model.name}");
    print("Slug: ${model.slug}"); // Use this slug with downloadModel()
    print("Size: ${model.sizeMb} MB");
    print("Downloaded: ${model.isDownloaded}");
    print("Supports Tool Calling: ${model.supportsToolCalling}");
    print("Supports Vision: ${model.supportsVision}");
    print("---");
  }
}
```

copied to clipboard

## Vision (Multimodal) [\#](https://pub.dev/packages/cactus\#vision-multimodal)

The `CactusLM` class supports vision-capable models that can analyze images. You can pass images alongside text messages to get AI-powered image descriptions and analysis.

```dart
Future<void> streamingVisionExample() async {
  final lm = CactusLM();
  await lm.initializeModel(params: CactusInitParams(model: 'lfm2-vl-450m'));

  // Stream the image analysis response
  final streamedResult = await lm.generateCompletionStream(
    messages: [\
      ChatMessage(\
        content: 'You are a helpful AI assistant that can analyze images.',\
        role: "system"\
      ),\
      ChatMessage(\
        content: 'What objects can you see in this image?',\
        role: "user",\
        images: ['/path/to/image.jpg']\
      )\
    ],
    params: CactusCompletionParams(maxTokens: 200)
  );

  // Process streaming output
  await for (final chunk in streamedResult.stream) {
    print(chunk);
  }
  lm.unload();
}
```

copied to clipboard

### Default Parameters [\#](https://pub.dev/packages/cactus\#default-parameters)

The `CactusLM` class provides sensible defaults for completion parameters:

- `maxTokens: 200` \- Maximum tokens to generate
- `stopSequences: ["<|im_end|>", "<end_of_turn>"]` \- Stop sequences for completion
- `completionMode: CompletionMode.local` \- Default to local-only inference.

### LLM API Reference [\#](https://pub.dev/packages/cactus\#llm-api-reference)

#### CactusLM Class

- `CactusLM({bool enableToolFiltering = true, ToolFilterConfig? toolFilterConfig})` \- Constructor. Set `enableToolFiltering` to false to disable automatic tool filtering. Provide `toolFilterConfig` to customize filtering behavior (defaults to `ToolFilterConfig.simple()` if not specified).
- `Future<void> downloadModel({String model = "qwen3-0.6", CactusProgressCallback? downloadProcessCallback})` \- Download a model by slug (e.g., "qwen3-0.6", "gemma3-270m", etc.). Use `getModels()` to see available model slugs. Defaults to "qwen3-0.6" if not specified.
- `Future<void> initializeModel({CactusInitParams? params})` \- Initialize model for inference
- `Future<CactusCompletionResult> generateCompletion({required List<ChatMessage> messages, CactusCompletionParams? params})` \- Generate text completion (uses default params if none provided). Automatically filters tools if `enableToolFiltering` is true (default).
- `Future<CactusStreamedCompletionResult> generateCompletionStream({required List<ChatMessage> messages, CactusCompletionParams? params})` \- Generate streaming text completion (uses default params if none provided). Automatically filters tools if `enableToolFiltering` is true (default).
- `Future<List<CactusModel>> getModels()` \- Fetch available models with caching
- `Future<CactusEmbeddingResult> generateEmbedding({required String text, String? modelName})` \- Generate text embeddings
- `void reset()` \- Reset the model context without unloading. Clears conversation history while keeping the model in memory for better performance.
- `void unload()` \- Free model from memory
- `bool isLoaded()` \- Check if model is loaded

#### Data Classes

- `CactusInitParams({String model = "qwen3-0.6", int? contextSize = 2048})` \- Model initialization parameters
- `CactusCompletionParams({String? model, double? temperature, int? topK, double? topP, int maxTokens = 200, List<String> stopSequences = ["<|im_end|>", "<end_of_turn>"], List<CactusTool>? tools, CompletionMode completionMode = CompletionMode.local, String? cactusToken, bool? forceTools})` \- Completion parameters
- `ChatMessage({required String content, required String role, int? timestamp, List<String> images})` \- Chat message format
- `CactusCompletionResult({required bool success, required String response, required double timeToFirstTokenMs, required double totalTimeMs, required double tokensPerSecond, required int prefillTokens, required int decodeTokens, required int totalTokens, List<ToolCall> toolCalls = []})` \- Contains response, timing metrics, tool calls, and success status
- `CactusStreamedCompletionResult({required Stream<String> stream, required Future<CactusCompletionResult> result})` \- Contains the stream and the final result of a streamed completion.
- `CactusModel({required DateTime createdAt, required String slug, required String downloadUrl, required int sizeMb, required bool supportsToolCalling, required bool supportsVision, required String name, bool isDownloaded = false, int quantization = 8})` \- Model information
- `CactusEmbeddingResult({required bool success, required List<double> embeddings, required int dimension, String? errorMessage})` \- Embedding generation result
- `CactusTool({required String name, required String description, required ToolParametersSchema parameters})` \- Function calling tool definition
- `ToolParametersSchema({String type = 'object', required Map<String, ToolParameter> properties})` \- Tool parameters schema with automatic required field extraction
- `ToolParameter({required String type, required String description, bool required = false})` \- Tool parameter specification
- `ToolCall({required String name, required Map<String, String> arguments})` \- Tool call result from model
- `ToolFilterConfig({ToolFilterStrategy strategy = ToolFilterStrategy.simple, int? maxTools, double similarityThreshold = 0.3})`\- Configuration for tool filtering behavior

  - Factory: `ToolFilterConfig.simple({int maxTools = 3})` \- Creates a simple keyword-based filter config
- `ToolFilterStrategy` \- Enum for tool filtering strategy (`simple` for keyword matching, `semantic` for embedding-based matching)
- `ToolFilterService({ToolFilterConfig? config, required CactusLM lm})` \- Service for filtering tools based on query relevance (used internally)
- `CactusProgressCallback = void Function(double? progress, String statusMessage, bool isError)` \- Progress callback for downloads
- `CompletionMode` \- Enum for completion mode (`local` or `hybrid`).

## Embeddings [\#](https://pub.dev/packages/cactus\#embeddings)

The `CactusLM` class also provides text embedding generation capabilities for semantic similarity, search, and other NLP tasks.

### Basic Usage [\#](https://pub.dev/packages/cactus\#basic-usage-2)

```dart
import 'package:cactus/cactus.dart';

Future<void> embeddingExample() async {
  final lm = CactusLM();

  try {
    // Download and initialize a model (same as for completions)
    await lm.downloadModel(model: "qwen3-0.6");
    await lm.initializeModel();

    // Generate embeddings for a text
    final result = await lm.generateEmbedding(
      text: "This is a sample text for embedding generation"
    );

    if (result.success) {
      print("Embedding dimension: ${result.dimension}");
      print("Embedding vector length: ${result.embeddings.length}");
      print("First few values: ${result.embeddings.take(5)}");
    } else {
      print("Embedding generation failed: ${result?.errorMessage}");
    }
  } finally {
    lm.unload();
  }
}
```

copied to clipboard

### Embedding API Reference [\#](https://pub.dev/packages/cactus\#embedding-api-reference)

#### CactusLM Class (Embedding Methods)

- `Future<CactusEmbeddingResult> generateEmbedding({required String text, String? modelName})` \- Generate text embeddings

#### Embedding Data Classes

- `CactusEmbeddingResult({required bool success, required List<double> embeddings, required int dimension, String? errorMessage})` \- Contains the generated embedding vector and metadata

## Speech-to-Text (STT) [\#](https://pub.dev/packages/cactus\#speech-to-text-stt)

The `CactusSTT` class provides high-quality local speech recognition capabilities powered by Whisper. It supports multiple languages and runs entirely on-device for privacy and offline functionality.

### Basic Usage [\#](https://pub.dev/packages/cactus\#basic-usage-3)

```dart
import 'package:cactus/cactus.dart';

Future<void> sttExample() async {
  final stt = CactusSTT();

  try {
    // Download a voice model with progress callback
    await stt.downloadModel(
      model: "whisper-tiny",
      downloadProcessCallback: (progress, status, isError) {
        if (isError) {
          print("Download error: $status");
        } else {
          print("$status ${progress != null ? '(${progress * 100}%)' : ''}");
        }
      },
    );

    // Initialize the speech recognition model
    await stt.initializeModel(params: CactusInitParams(model: "whisper-tiny"));

    // Transcribe audio from file
    final result = await stt.transcribe(
      audioFilePath: "/path/to/audio/file.wav",
    );

    if (result.success) {
      print("Transcribed text: ${result.text}");
      print("Time to first token: ${result.timeToFirstTokenMs}ms");
      print("Total time: ${result.totalTimeMs}ms");
      print("Tokens per second: ${result.tokensPerSecond}");
    } else {
      print("Transcription failed: ${result.errorMessage}");
    }
  } finally {
    // Clean up
    stt.unload();
  }
}
```

copied to clipboard

### Streaming Transcription [\#](https://pub.dev/packages/cactus\#streaming-transcription)

```dart
Future<void> streamingTranscriptionExample() async {
  final stt = CactusSTT();

  await stt.downloadModel(model: "whisper-tiny");
  await stt.initializeModel(params: CactusInitParams(model: "whisper-tiny"));

  // Get streaming transcription result
  final streamedResult = await stt.transcribeStream(
    audioFilePath: "/path/to/audio/file.wav",
  );

  // Process streaming output token by token
  await for (final token in streamedResult.stream) {
    print(token);
  }

  // Get the final result with timing metrics
  final finalResult = await streamedResult.result;
  if (finalResult.success) {
    print("Final transcription: ${finalResult.text}");
    print("Tokens per second: ${finalResult.tokensPerSecond}");
  }

  stt.unload();
}
```

copied to clipboard

### Using Different Whisper Models [\#](https://pub.dev/packages/cactus\#using-different-whisper-models)

```dart
Future<void> whisperModelsExample() async {
  // Smaller models are faster, larger models are more accurate

  // Tiny model - Fastest, good for real-time
  final tinySTT = CactusSTT();
  await tinySTT.downloadModel(model: "whisper-tiny");
  await tinySTT.initializeModel(params: CactusInitParams(model: "whisper-tiny"));

  final result1 = await tinySTT.transcribe(
    audioFilePath: "/path/to/audio.wav"
  );
  print("Tiny model result: ${result1.text}");
  tinySTT.unload();

  // Base model - More accurate, slightly slower
  final baseSTT = CactusSTT();
  await baseSTT.downloadModel(model: "whisper-base");
  await baseSTT.initializeModel(params: CactusInitParams(model: "whisper-base"));

  final result2 = await baseSTT.transcribe(
    audioFilePath: "/path/to/audio.wav"
  );
  print("Base model result: ${result2.text}");
  baseSTT.unload();
}
```

copied to clipboard

### Custom Transcription Parameters [\#](https://pub.dev/packages/cactus\#custom-transcription-parameters)

```dart
Future<void> customParametersExample() async {
  final stt = CactusSTT();

  await stt.downloadModel(model: "whisper-tiny");
  await stt.initializeModel(params: CactusInitParams(model: "whisper-tiny"));

  // Configure custom transcription parameters
  final params = CactusTranscriptionParams(
    maxTokens: 4096,
    stopSequences: ["<|startoftranscript|>"],
  );

  final result = await stt.transcribe(
    audioFilePath: "/path/to/audio/file.wav",
    params: params,
  );

  if (result.success) {
    print("Custom transcription: ${result.text}");
  }

  stt.unload();
}
```

copied to clipboard

### Fetching Available Voice Models [\#](https://pub.dev/packages/cactus\#fetching-available-voice-models)

```dart
Future<void> fetchVoiceModelsExample() async {
  final stt = CactusSTT();

  // Get list of available voice models
  final models = await stt.getVoiceModels();

  for (final model in models) {
    print("Model: ${model.slug}");
    print("Size: ${model.sizeMb} MB");
    print("File name: ${model.fileName}");
    print("Downloaded: ${model.isDownloaded}");
    print("---");
  }
}
```

copied to clipboard

### Default Parameters [\#](https://pub.dev/packages/cactus\#default-parameters-2)

The `CactusSTT` class uses sensible defaults:

- Default initialization parameters match `CactusInitParams` (context size: 2048)
- Default transcription parameters: `maxTokens: 2048`, `stopSequences: ["<|startoftranscript|>"]`
- Default Whisper prompt: `<|startoftranscript|><|en|><|transcribe|><|notimestamps|>`

### STT API Reference [\#](https://pub.dev/packages/cactus\#stt-api-reference)

#### CactusSTT Class

- `CactusSTT()` \- Constructor
- `Future<void> downloadModel({required String model, CactusProgressCallback? downloadProcessCallback})` \- Download a voice model (e.g., "whisper-tiny", "whisper-base")
- `Future<void> initializeModel({CactusInitParams? params})` \- Initialize speech recognition model (uses last initialized model if params not provided)
- `Future<CactusTranscriptionResult> transcribe({String? audioFilePath, Stream<Uint8List>? audioStream, Function(CactusTranscriptionResult)? onChunk, String prompt = whisperPrompt, CactusTranscriptionParams? params})` \- Transcribe audio from either a file path or an audio stream. Must provide either `audioFilePath` or `audioStream`, but not both. When using `audioStream`, the `onChunk` callback receives transcription results as they're processed.
- `Future<CactusStreamedTranscriptionResult> transcribeStream({String? audioFilePath, Stream<Uint8List>? audioStream, String prompt = whisperPrompt, CactusTranscriptionParams? params})` \- Stream transcription token by token from either a file path or an audio stream
- `void reset()` \- Reset the model context without unloading. Clears transcription history while keeping the model in memory for better performance.
- `void unload()` \- Free model from memory
- `bool isLoaded()` \- Check if model is loaded
- `Future<List<VoiceModel>> getVoiceModels()` \- Fetch available voice models with caching

#### STT Data Classes

- `CactusInitParams({String model = "qwen3-0.6", int? contextSize = 2048})` \- Model initialization parameters (reused from LLM API)
- `CactusTranscriptionParams({int maxTokens = 2048, List<String> stopSequences = ["<|startoftranscript|>"]})` \- Transcription parameters
- `CactusTranscriptionResult({required bool success, required String text, double timeToFirstTokenMs = 0.0, double totalTimeMs = 0.0, double tokensPerSecond = 0.0, String? errorMessage})` \- Transcription result with timing metrics
- `CactusStreamedTranscriptionResult({required Stream<String> stream, required Future<CactusTranscriptionResult> result})` \- Contains the token stream and the final transcription result
- `VoiceModel({required DateTime createdAt, required String slug, required String downloadUrl, required int sizeMb, required String fileName, bool isDownloaded = false})` \- Voice model information
- `CactusProgressCallback = void Function(double? progress, String statusMessage, bool isError)` \- Progress callback for model downloads

## Retrieval-Augmented Generation (RAG) [\#](https://pub.dev/packages/cactus\#retrieval-augmented-generation-rag)

The `CactusRAG` class provides a local vector database for storing, managing, and searching documents with automatic text chunking. It uses [ObjectBox](https://objectbox.io/) for efficient on-device storage and retrieval, making it ideal for building RAG applications that run entirely locally.

**Key Features:**

- **Automatic Text Chunking**: Documents are automatically split into configurable chunks with overlap for better context preservation
- **Embedding Generation**: Integrates with `CactusLM` to automatically generate embeddings for each chunk
- **Vector Search**: Performs efficient nearest neighbor search using HNSW (Hierarchical Navigable Small World) index with squared Euclidean distance
- **Document Management**: Supports create, read, update, and delete operations with automatic chunk handling
- **Local-First**: All data and embeddings are stored on-device using ObjectBox for privacy and offline functionality

### Basic Usage [\#](https://pub.dev/packages/cactus\#basic-usage-4)

**Note on Distance Scores**: The search method returns squared Euclidean distance values where **lower distance = more similar** vectors. Results are automatically sorted with the most similar chunks first. You don't need to convert to similarity scores - just use the distance values directly for filtering or ranking.

```dart
import 'package:cactus/cactus.dart';

Future<void> ragExample() async {
  final lm = CactusLM();
  final rag = CactusRAG();

  try {
    // 1. Initialize LM and RAG
    await lm.downloadModel(model: "qwen3-0.6");
    await lm.initializeModel();
    await rag.initialize();

    // 2. Set up the embedding generator (uses the LM to generate embeddings)
    rag.setEmbeddingGenerator((text) async {
      final result = await lm.generateEmbedding(text: text);
      return result.embeddings;
    });

    // 3. Configure chunking parameters (optional - defaults: chunkSize=512, chunkOverlap=64)
    rag.setChunking(chunkSize: 1024, chunkOverlap: 128);

    // 4. Store a document (automatically chunks and generates embeddings)
    final docContent = "The Eiffel Tower is a wrought-iron lattice tower on the Champ de Mars in Paris, France. It was constructed from 1887 to 1889 as the entrance arch to the 1889 World's Fair. The tower is 330 metres tall, about the same height as an 81-storey building.";

    final document = await rag.storeDocument(
      fileName: "eiffel_tower.txt",
      filePath: "/path/to/eiffel_tower.txt",
      content: docContent,
      fileSize: docContent.length,
      fileHash: "abc123", // Optional file hash for versioning
    );
    print("Document stored with ${document.chunks.length} chunks.");

    // 5. Search for similar content using vector search
    final searchResults = await rag.search(
      text: "What is the famous landmark in Paris?",
      limit: 5, // Get top 5 most similar chunks
    );

    print("\nFound ${searchResults.length} similar chunks:");
    for (final result in searchResults) {
      print("- Chunk from ${result.chunk.document.target?.fileName} (Distance: ${result.distance.toStringAsFixed(2)})");
      print("  Content: ${result.chunk.content.substring(0, 50)}...");
    }
  } finally {
    // 6. Clean up
    lm.unload();
    await rag.close();
  }
}
```

copied to clipboard

### RAG API Reference [\#](https://pub.dev/packages/cactus\#rag-api-reference)

#### CactusRAG Class

- `Future<void> initialize()` \- Initialize the local ObjectBox database
- `Future<void> close()` \- Close the database connection
- `void setEmbeddingGenerator(EmbeddingGenerator generator)` \- Set the function used to generate embeddings for text chunks
- `void setChunking({required int chunkSize, required int chunkOverlap})` \- Configure text chunking parameters (defaults: chunkSize=512, chunkOverlap=64)
- `int get chunkSize` \- Get current chunk size setting
- `int get chunkOverlap` \- Get current chunk overlap setting
- `List<String> chunkContent(String content, {int? chunkSize, int? chunkOverlap})` \- Manually chunk text content (visible for testing)
- `Future<Document> storeDocument({required String fileName, required String filePath, required String content, int? fileSize, String? fileHash})` \- Store a document with automatic chunking and embedding generation
- `Future<Document?> getDocumentByFileName(String fileName)` \- Retrieve a document by its file name
- `Future<List<Document>> getAllDocuments()` \- Get all stored documents
- `Future<void> updateDocument(Document document)` \- Update an existing document and its chunks
- `Future<void> deleteDocument(int id)` \- Delete a document and all its chunks by ID
- `Future<List<ChunkSearchResult>> search({String? text, int limit = 10})` \- Search for the nearest document chunks by generating embeddings for the query text and performing vector similarity search. Results are sorted by distance (lower = more similar)
- `Future<DatabaseStats> getStats()` \- Get statistics about the database

#### RAG Data Classes

- `Document({int id = 0, required String fileName, required String filePath, DateTime? createdAt, DateTime? updatedAt, int? fileSize, String? fileHash})` \- Represents a stored document with its metadata and associated chunks. Has a `content` getter that joins all chunk contents.
- `DocumentChunk({int id = 0, required String content, required List<double> embeddings})` \- Represents a text chunk with its content and embeddings (1024-dimensional vectors by default)
- `ChunkSearchResult({required DocumentChunk chunk, required double distance})` \- Contains a document chunk and its distance score from the query vector (lower distance = more similar). Distance is squared Euclidean distance from ObjectBox HNSW index
- `DatabaseStats({required int totalDocuments, required int documentsWithEmbeddings, required int totalContentLength})` \- Contains statistics about the document store including total documents, chunks, and content length
- `EmbeddingGenerator = Future<List<double>> Function(String text)` \- Function type for generating embeddings from text

## Platform-Specific Setup [\#](https://pub.dev/packages/cactus\#platform-specific-setup)

### Android [\#](https://pub.dev/packages/cactus\#android)

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<!-- Required for speech-to-text functionality -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

copied to clipboard

### iOS [\#](https://pub.dev/packages/cactus\#ios)

Add microphone usage description to your `ios/Runner/Info.plist` for speech-to-text functionality:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone for speech-to-text transcription.</string>
```

copied to clipboard

### macOS [\#](https://pub.dev/packages/cactus\#macos)

Add the following to your `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<!-- Network access for model downloads -->
<key>com.apple.security.network.client</key>
<true/>
<!-- Microphone access for speech-to-text -->
<key>com.apple.security.device.microphone</key>
<true/>
```

copied to clipboard

## Performance Tips [\#](https://pub.dev/packages/cactus\#performance-tips)

1. **Model Selection**: Choose smaller models for faster inference on mobile devices
2. **Context Size**: Reduce context size for lower memory usage (e.g., 1024 instead of 2048)
3. **Memory Management**: Always call `unload()` when done with models
4. **Batch Processing**: Reuse initialized models for multiple completions
5. **Background Processing**: Use `Isolate` for heavy operations to keep UI responsive
6. **Model Caching**: Use `getModels()` for efficient model discovery - results are cached locally to reduce network requests

## Example App [\#](https://pub.dev/packages/cactus\#example-app)

Check out the example app in the `example/` directory for a complete Flutter implementation showing:

- Model discovery and fetching available models
- Model downloading with real-time progress indicators
- Text completion with both regular and streaming modes
- Vision/multimodal image analysis (`example/lib/pages/vision.dart`)
- Speech-to-text transcription with Whisper
- Voice model management and provider switching
- Embedding generation
- RAG document storage and search
- Error handling and status management
- Material Design UI integration

To run the example:

```bash
cd example
flutter pub get
flutter run
```

copied to clipboard

## Support [\#](https://pub.dev/packages/cactus\#support)

- 📖 [Documentation](https://cactuscompute.com/docs)
- 💬 [Discord Community](https://discord.gg/bNurx3AXTJ)
- 🐛 [Issues](https://github.com/cactus-compute/cactus-flutter/issues)
- 🤗 [Models on Hugging Face](https://huggingface.co/Cactus-Compute/models)

[23\\
\\
likes\\
\\
120\\
\\
points\\
\\
349\\
\\
downloads](https://pub.dev/packages/cactus/score)

### Documentation

[API reference](https://pub.dev/documentation/cactus/latest/)

### Publisher

[![verified publisher](https://pub.dev/static/hash-ilufue8n/img/material-icon-verified.svg)cactuscompute.com](https://pub.dev/publishers/cactuscompute.com)

### Weekly Downloads

2025.06.16 - 2026.05.11

### Metadata

Build AI apps with Cactus

[Homepage](https://cactuscompute.com/)

[Repository (GitHub)](https://github.com/cactus-compute/cactus-flutter)

[View/report issues](https://github.com/cactus-compute/cactus-flutter/issues)

### License

![](https://pub.dev/static/hash-ilufue8n/img/material-icon-balance.svg)unknown ( [license](https://pub.dev/packages/cactus/license))

### Dependencies

[android\_id](https://pub.dev/packages/android_id "^0.4.0"), [archive](https://pub.dev/packages/archive "^4.0.7"), [device\_info\_plus](https://pub.dev/packages/device_info_plus "^11.5.0"), [ffi](https://pub.dev/packages/ffi "^2.1.4"), [flat\_buffers](https://pub.dev/packages/flat_buffers "^23.5.26"), [flutter](https://api.flutter.dev/), [http](https://pub.dev/packages/http "^1.5.0"), [objectbox](https://pub.dev/packages/objectbox "^5.0.0"), [objectbox\_flutter\_libs](https://pub.dev/packages/objectbox_flutter_libs "^5.0.1"), [package\_info\_plus](https://pub.dev/packages/package_info_plus "^8.3.1"), [path](https://pub.dev/packages/path "^1.9.1"), [path\_provider](https://pub.dev/packages/path_provider "^2.1.5"), [permission\_handler](https://pub.dev/packages/permission_handler "^12.0.1"), [record](https://pub.dev/packages/record "^6.1.1"), [shared\_preferences](https://pub.dev/packages/shared_preferences "^2.5.3"), [uuid](https://pub.dev/packages/uuid "^4.5.1")

### More

[Packages that depend on cactus](https://pub.dev/packages?q=dependency%3Acactus)

[Packages that implement cactus](https://pub.dev/packages?q=implements-federated-plugin%3Acactus)

### ← Metadata

[23\\
\\
likes\\
\\
120\\
\\
points\\
\\
349\\
\\
downloads](https://pub.dev/packages/cactus/score)

### Documentation

[API reference](https://pub.dev/documentation/cactus/latest/)

### Publisher

[![verified publisher](https://pub.dev/static/hash-ilufue8n/img/material-icon-verified.svg)cactuscompute.com](https://pub.dev/publishers/cactuscompute.com)

### Weekly Downloads

2025.06.16 - 2026.05.11

### Metadata

Build AI apps with Cactus

[Homepage](https://cactuscompute.com/)

[Repository (GitHub)](https://github.com/cactus-compute/cactus-flutter)

[View/report issues](https://github.com/cactus-compute/cactus-flutter/issues)

### License

![](https://pub.dev/static/hash-ilufue8n/img/material-icon-balance.svg)unknown ( [license](https://pub.dev/packages/cactus/license))

### Dependencies

[android\_id](https://pub.dev/packages/android_id "^0.4.0"), [archive](https://pub.dev/packages/archive "^4.0.7"), [device\_info\_plus](https://pub.dev/packages/device_info_plus "^11.5.0"), [ffi](https://pub.dev/packages/ffi "^2.1.4"), [flat\_buffers](https://pub.dev/packages/flat_buffers "^23.5.26"), [flutter](https://api.flutter.dev/), [http](https://pub.dev/packages/http "^1.5.0"), [objectbox](https://pub.dev/packages/objectbox "^5.0.0"), [objectbox\_flutter\_libs](https://pub.dev/packages/objectbox_flutter_libs "^5.0.1"), [package\_info\_plus](https://pub.dev/packages/package_info_plus "^8.3.1"), [path](https://pub.dev/packages/path "^1.9.1"), [path\_provider](https://pub.dev/packages/path_provider "^2.1.5"), [permission\_handler](https://pub.dev/packages/permission_handler "^12.0.1"), [record](https://pub.dev/packages/record "^6.1.1"), [shared\_preferences](https://pub.dev/packages/shared_preferences "^2.5.3"), [uuid](https://pub.dev/packages/uuid "^4.5.1")

### More

[Packages that depend on cactus](https://pub.dev/packages?q=dependency%3Acactus)

[Packages that implement cactus](https://pub.dev/packages?q=implements-federated-plugin%3Acactus)

Back

![previous](https://pub.dev/static/hash-ilufue8n/img/keyboard_arrow_left.svg)

![next](https://pub.dev/static/hash-ilufue8n/img/keyboard_arrow_right.svg)

[Dart language](https://dart.dev/) [Report package](https://pub.dev/report?subject=package%3Acactus&url=https%3A%2F%2Fpub.dev%2Fpackages%2Fcactus) [Policy](https://pub.dev/policy) [Terms](https://www.google.com/intl/en/policies/terms/) [API Terms](https://developers.google.com/terms/) [Security](https://pub.dev/security) [Privacy](https://www.google.com/intl/en/policies/privacy/) [Help](https://pub.dev/help) [![RSS](https://pub.dev/static/hash-ilufue8n/img/rss-feed-icon.svg)](https://pub.dev/feed.atom) [![bug report](https://pub.dev/static/hash-ilufue8n/img/bug-report-white-96px.png)](https://github.com/dart-lang/pub-dev/issues/new?body=URL%3A+https%3A%2F%2Fpub.dev%2Fpackages%2Fcactus%0A%0A%3CDescribe+your+issue+or+suggestion+here%3E&title=%3CSummarize+your+issues+here%3E&labels=Area%3A+site+feedback)