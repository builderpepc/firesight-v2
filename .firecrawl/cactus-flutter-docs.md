[Skip to content](https://docs.cactuscompute.com/latest/flutter/#cactus-for-flutter)

# Cactus for Flutter [¶](https://docs.cactuscompute.com/latest/flutter/\#cactus-for-flutter "Permanent link")

Run AI models on-device with dart:ffi direct bindings for iOS, macOS, and Android.

> **Model weights:** Pre-converted weights for all supported models at [huggingface.co/Cactus-Compute](https://huggingface.co/Cactus-Compute).

## Building [¶](https://docs.cactuscompute.com/latest/flutter/\#building "Permanent link")

```
git clone https://github.com/cactus-compute/cactus && cd cactus && source ./setup
cactus build --flutter
```

Build output:

| File | Platform |
| --- | --- |
| `libcactus.so` | Android (arm64-v8a) |
| `cactus-ios.xcframework` | iOS |
| `cactus-macos.xcframework` | macOS |

See the main [README.md](https://docs.cactuscompute.com/latest/) for how to use CLI & download weights

## Integration [¶](https://docs.cactuscompute.com/latest/flutter/\#integration "Permanent link")

### Android [¶](https://docs.cactuscompute.com/latest/flutter/\#android "Permanent link")

1. Copy `libcactus.so` to `android/app/src/main/jniLibs/arm64-v8a/`
2. Copy `cactus.dart` to your `lib/` folder

### iOS [¶](https://docs.cactuscompute.com/latest/flutter/\#ios "Permanent link")

1. Copy `cactus-ios.xcframework` to your `ios/` folder
2. Open `ios/Runner.xcworkspace` in Xcode
3. Drag the xcframework into the project
4. In Runner target > General > "Frameworks, Libraries, and Embedded Content", set to "Embed & Sign"
5. Copy `cactus.dart` to your `lib/` folder

### macOS [¶](https://docs.cactuscompute.com/latest/flutter/\#macos "Permanent link")

1. Copy `cactus-macos.xcframework` to your `macos/` folder
2. Open `macos/Runner.xcworkspace` in Xcode
3. Drag the xcframework into the project
4. In Runner target > General > "Frameworks, Libraries, and Embedded Content", set to "Embed & Sign"
5. Copy `cactus.dart` to your `lib/` folder

## Usage [¶](https://docs.cactuscompute.com/latest/flutter/\#usage "Permanent link")

Handles are typed as `CactusModelT`, `CactusIndexT`, and `CactusStreamTranscribeT` (all `Pointer<Void>` aliases). All functions are top-level.

### Basic Completion [¶](https://docs.cactuscompute.com/latest/flutter/\#basic-completion "Permanent link")

```
import 'cactus.dart';

final model = cactusInit('/path/to/model', null, false);
final messages = '[{"role":"user","content":"What is the capital of France?"}]';
final resultJson = cactusComplete(model, messages, null, null, null);
print(resultJson);
cactusDestroy(model);
```

For vision models (LFM2-VL, LFM2.5-VL, Gemma4, Qwen3.5), add `"images": ["path/to/image.png"]` to any message. For audio models (Gemma4), add `"audio": ["path/to/audio.wav"]`. See [Engine API](https://docs.cactuscompute.com/latest/docs/cactus_engine/) for details.

### Completion with Options and Streaming [¶](https://docs.cactuscompute.com/latest/flutter/\#completion-with-options-and-streaming "Permanent link")

```
import 'cactus.dart';
import 'dart:io';

final options = '{"max_tokens":256,"temperature":0.7}';

final resultJson = cactusComplete(model, messages, options, null, (token, tokenId) {
  stdout.write(token);
});
print(resultJson);
```

### Prefill [¶](https://docs.cactuscompute.com/latest/flutter/\#prefill "Permanent link")

Pre-processes input text and populates the KV cache without generating output tokens. This reduces latency for subsequent calls to `cactusComplete`.

```
String cactusPrefill(
  CactusModelT model,
  String messagesJson,
  String? optionsJson,
  String? toolsJson,
)
```

```
final tools = '[{"type":"function","function":{"name":"get_weather","description":"Get weather for a location","parameters":{"type":"object","properties":{"location":{"type":"string"}},"required":["location"]}}}]';

final messages = '[{"role":"system","content":"You are a helpful assistant."},{"role":"user","content":"What is the weather in Paris?"}]';

final resultJson = cactusPrefill(model, messages, null, tools);

final completionMessages = '[{"role":"system","content":"You are a helpful assistant."},{"role":"user","content":"What is the weather in Paris?"},{"role":"user","content":"What about SF?"}]';

final completion = cactusComplete(model, completionMessages, null, tools, null);
```

**Response format:**

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

### Audio Transcription [¶](https://docs.cactuscompute.com/latest/flutter/\#audio-transcription "Permanent link")

```
import 'cactus.dart';
import 'dart:typed_data';

// From file
final resultJson = cactusTranscribe(model, '/path/to/audio.wav', null, null, null, null);
print(resultJson);

// From PCM data (16 kHz mono)
final pcmData = Uint8List.fromList([...]);
final resultJson2 = cactusTranscribe(model, null, null, null, null, pcmData);
print(resultJson2);
```

`segments` contains timestamps (seconds): phrase-level for Whisper, word-level for Parakeet TDT, one segment per transcription window for Parakeet CTC and Moonshine (consecutive VAD speech regions up to 30s).

```
import 'dart:convert';

final result = jsonDecode(resultJson) as Map<String, dynamic>;
for (final seg in result['segments'] as List) {
  print('[${seg['start']}s - ${seg['end']}s] ${seg['text']}');
}
```

**Custom vocabulary** biases the decoder toward domain-specific words (supported for Whisper and Moonshine models). Pass `custom_vocabulary` and `vocabulary_boost` in the options JSON:

```
final options = '{"custom_vocabulary": ["Omeprazole", "HIPAA", "Cactus"], "vocabulary_boost": 3.0}';
final result = cactusTranscribe(model, '/path/to/audio.wav', '', options, null, null);
```

### Streaming Transcription [¶](https://docs.cactuscompute.com/latest/flutter/\#streaming-transcription "Permanent link")

```
import 'cactus.dart';
import 'dart:typed_data';

final stream = cactusStreamTranscribeStart(model, null);

final Uint8List audioChunk = ...;
final partialJson = cactusStreamTranscribeProcess(stream, audioChunk);
print(partialJson);

final finalJson = cactusStreamTranscribeStop(stream);
print(finalJson);
```

Streaming also accepts `custom_vocabulary` in the options passed to `cactusStreamTranscribeStart`. The bias is applied for the lifetime of the stream session.

### Embeddings [¶](https://docs.cactuscompute.com/latest/flutter/\#embeddings "Permanent link")

```
import 'cactus.dart';
import 'dart:typed_data';

final Float32List embedding      = cactusEmbed(model, 'Hello, world!', true);
final Float32List imageEmbedding = cactusImageEmbed(model, '/path/to/image.jpg');
final Float32List audioEmbedding = cactusAudioEmbed(model, '/path/to/audio.wav');
```

### Tokenization [¶](https://docs.cactuscompute.com/latest/flutter/\#tokenization "Permanent link")

```
import 'cactus.dart';

final List<int> tokens = cactusTokenize(model, 'Hello, world!');
final String scores = cactusScoreWindow(model, tokens, 0, tokens.length, 512);
```

### Language Detection [¶](https://docs.cactuscompute.com/latest/flutter/\#language-detection "Permanent link")

```
import 'cactus.dart';
import 'dart:typed_data';

// From file
final resultJson = cactusDetectLanguage(model, '/path/to/audio.wav', null, null);
print(resultJson);

// From PCM data (16 kHz mono)
final Uint8List pcmData = ...;
final resultJson2 = cactusDetectLanguage(model, null, null, pcmData);
print(resultJson2);
```

### VAD [¶](https://docs.cactuscompute.com/latest/flutter/\#vad "Permanent link")

```
import 'cactus.dart';

final String vadJson = cactusVad(model, '/path/to/audio.wav', null, null);
print(vadJson);
```

### Diarize [¶](https://docs.cactuscompute.com/latest/flutter/\#diarize "Permanent link")

```
import 'cactus.dart';

final String diarizeJson = cactusDiarize(model, '/path/to/audio.wav', null, null);
print(diarizeJson);
```

Options (all optional):
\- `step_ms` (int, default 1000) — sliding window stride in milliseconds
\- `threshold` (float) — zero out per-speaker scores below this value
\- `num_speakers` (int) — keep only the N most active speakers
\- `min_speakers` / `max_speakers` (int) — speaker count bounds
\- `raw_powerset` (bool, default false) — return raw 7-class powerset scores instead of 3-speaker probabilities

### Embed Speaker [¶](https://docs.cactuscompute.com/latest/flutter/\#embed-speaker "Permanent link")

```
import 'cactus.dart';

final String embedJson = cactusEmbedSpeaker(model, '/path/to/audio.wav', null, null);
print(embedJson);

// With diarization mask for speaker-specific embedding
final String embedJson = cactusEmbedSpeaker(model, '/path/to/audio.wav', null, null, maskWeights);
```

Returns a 256-dimensional speaker embedding. When `maskWeights` (a per-frame weight array from diarization) is provided, the embedding is extracted using weighted stats pooling for speaker-specific embeddings.

### RAG [¶](https://docs.cactuscompute.com/latest/flutter/\#rag "Permanent link")

```
import 'cactus.dart';

final String result = cactusRagQuery(model, 'What is machine learning?', 5);
print(result);
```

### Vector Index [¶](https://docs.cactuscompute.com/latest/flutter/\#vector-index "Permanent link")

```
import 'cactus.dart';

final embDim = 4;
final index = cactusIndexInit('/path/to/index', embDim);

cactusIndexAdd(
  index,
  [1, 2],
  ['Document 1', 'Document 2'],
  [[0.1, 0.2, 0.3, 0.4], [0.5, 0.6, 0.7, 0.8]],
  null,
);

final resultsJson = cactusIndexQuery(index, [0.1, 0.2, 0.3, 0.4], null);
final getJson = cactusIndexGet(index, [1, 2]);

cactusIndexDelete(index, [2]);
cactusIndexCompact(index);
cactusIndexDestroy(index);
```

## API Reference [¶](https://docs.cactuscompute.com/latest/flutter/\#api-reference "Permanent link")

All functions are top-level and mirror the C FFI directly. Functions that return a value throw `Exception` on failure;

### Types [¶](https://docs.cactuscompute.com/latest/flutter/\#types "Permanent link")

```
typedef CactusModelT            = Pointer<Void>;
typedef CactusIndexT            = Pointer<Void>;
typedef CactusStreamTranscribeT = Pointer<Void>;
```

### Init / Lifecycle [¶](https://docs.cactuscompute.com/latest/flutter/\#init-lifecycle "Permanent link")

```
CactusModelT cactusInit(String modelPath, String? corpusDir, bool cacheIndex)
void cactusDestroy(CactusModelT model)
void cactusReset(CactusModelT model)
void cactusStop(CactusModelT model)
String cactusGetLastError()
```

### Prefill [¶](https://docs.cactuscompute.com/latest/flutter/\#prefill_1 "Permanent link")

```
String cactusPrefill(
  CactusModelT model,
  String messagesJson,
  String? optionsJson,
  String? toolsJson,
  {Uint8List? pcmData}
)
```

### Completion [¶](https://docs.cactuscompute.com/latest/flutter/\#completion "Permanent link")

```
String cactusComplete(
  CactusModelT model,
  String messagesJson,
  String? optionsJson,
  String? toolsJson,
  void Function(String token, int tokenId)? callback,
  {Uint8List? pcmData}
)
```

### Transcription [¶](https://docs.cactuscompute.com/latest/flutter/\#transcription "Permanent link")

```
String cactusTranscribe(
  CactusModelT model,
  String? audioPath,
  String? prompt,
  String? optionsJson,
  void Function(String token, int tokenId)? callback,
  Uint8List? pcmData,
)

CactusStreamTranscribeT cactusStreamTranscribeStart(CactusModelT model, String? optionsJson)
String cactusStreamTranscribeProcess(CactusStreamTranscribeT stream, Uint8List pcmData)
String cactusStreamTranscribeStop(CactusStreamTranscribeT stream)
```

### Embeddings [¶](https://docs.cactuscompute.com/latest/flutter/\#embeddings_1 "Permanent link")

```
Float32List cactusEmbed(CactusModelT model, String text, bool normalize)
Float32List cactusImageEmbed(CactusModelT model, String imagePath)
Float32List cactusAudioEmbed(CactusModelT model, String audioPath)
```

### Tokenization / Scoring [¶](https://docs.cactuscompute.com/latest/flutter/\#tokenization-scoring "Permanent link")

```
List<int> cactusTokenize(CactusModelT model, String text)
String cactusScoreWindow(CactusModelT model, List<int> tokens, int start, int end, int context)
```

### Detect Language [¶](https://docs.cactuscompute.com/latest/flutter/\#detect-language "Permanent link")

```
String cactusDetectLanguage(CactusModelT model, String? audioPath, String? optionsJson, Uint8List? pcmData)
```

### VAD [¶](https://docs.cactuscompute.com/latest/flutter/\#vad_1 "Permanent link")

```
String cactusVad(CactusModelT model, String? audioPath, String? optionsJson, Uint8List? pcmData)
```

### Diarize [¶](https://docs.cactuscompute.com/latest/flutter/\#diarize_1 "Permanent link")

```
String cactusDiarize(CactusModelT model, String? audioPath, String? optionsJson, Uint8List? pcmData)
```

### Embed Speaker [¶](https://docs.cactuscompute.com/latest/flutter/\#embed-speaker_1 "Permanent link")

```
String cactusEmbedSpeaker(CactusModelT model, String? audioPath, String? optionsJson, Uint8List? pcmData, [Float32List? maskWeights])
```

### RAG [¶](https://docs.cactuscompute.com/latest/flutter/\#rag_1 "Permanent link")

```
String cactusRagQuery(CactusModelT model, String query, int topK)
```

### Vector Index [¶](https://docs.cactuscompute.com/latest/flutter/\#vector-index_1 "Permanent link")

```
CactusIndexT cactusIndexInit(String indexDir, int embeddingDim)
void cactusIndexDestroy(CactusIndexT index)
int cactusIndexAdd(CactusIndexT index, List<int> ids, List<String> documents, List<List<double>> embeddings, List<String>? metadatas)
int cactusIndexDelete(CactusIndexT index, List<int> ids)
String cactusIndexGet(CactusIndexT index, List<int> ids)
String cactusIndexQuery(CactusIndexT index, List<double> embedding, String? optionsJson)
int cactusIndexCompact(CactusIndexT index)
```

### Logging [¶](https://docs.cactuscompute.com/latest/flutter/\#logging "Permanent link")

```
void cactusLogSetLevel(int level)  // 0=DEBUG 1=INFO 2=WARN 3=ERROR 4=NONE
void cactusLogSetCallback(void Function(int level, String component, String message)? onLog)
```

### Telemetry [¶](https://docs.cactuscompute.com/latest/flutter/\#telemetry "Permanent link")

```
void cactusSetTelemetryEnvironment(String cacheLocation)
void cactusSetAppId(String appId)
void cactusTelemetryFlush()
void cactusTelemetryShutdown()
```

## Bundling Model Weights [¶](https://docs.cactuscompute.com/latest/flutter/\#bundling-model-weights "Permanent link")

Models must be accessible via file path at runtime.

### Android [¶](https://docs.cactuscompute.com/latest/flutter/\#android_1 "Permanent link")

Copy from assets to internal storage on first launch:

```
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<String> getModelPath() async {
  final dir = await getApplicationDocumentsDirectory();
  final modelFile = File('${dir.path}/model');

  if (!await modelFile.exists()) {
    final data = await rootBundle.load('assets/model');
    await modelFile.writeAsBytes(data.buffer.asUint8List());
  }

  return modelFile.path;
}
```

### iOS/macOS [¶](https://docs.cactuscompute.com/latest/flutter/\#iosmacos "Permanent link")

Add model to bundle and access via path:

```
import 'dart:io';

final path = '${Directory.current.path}/model';
```

## Requirements [¶](https://docs.cactuscompute.com/latest/flutter/\#requirements "Permanent link")

- Flutter 3.0+
- Dart 2.17+
- iOS 13.0+ / macOS 13.0+
- Android API 21+ / arm64-v8a

## See Also [¶](https://docs.cactuscompute.com/latest/flutter/\#see-also "Permanent link")

- [Cactus Engine API](https://docs.cactuscompute.com/latest/docs/cactus_engine/) — Full C API reference underlying the Flutter bindings
- [Cactus Index API](https://docs.cactuscompute.com/latest/docs/cactus_index/) — Vector database API for RAG applications
- [Fine-tuning Guide](https://docs.cactuscompute.com/latest/docs/finetuning/) — Deploy custom fine-tunes to mobile
- [Swift SDK](https://docs.cactuscompute.com/latest/apple/) — Native Swift alternative for Apple platforms
- [Kotlin/Android SDK](https://docs.cactuscompute.com/latest/android/) — Native Kotlin alternative for Android

Back to top