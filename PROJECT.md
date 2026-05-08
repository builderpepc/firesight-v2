# Project Overview
We are building FireSight: Voice automation for fire department pre-incident inspections.

## The Problem We Solve
Fire departments - the real firefighters themselves, not (just) city officials - have to spend countless hours every year performing inspections on buildings called pre-incident surveys. The purpose of these inspections is to assess risk and strategize for potential emergencies. For high-risk buildings like hospitals or schools, these inspections can happen multiple times per year. As part of these inspections, firefighters need to record countless data points in outdated, clunky web forms or even on paper. 

We spoke to real industry professionals and firefighters at departments like FDNY and Colonia for feedback and insights. There's a real need here, and we think we can build a better solution with the technology available to us today.

## How Our Project Works
Rather than making firefighters meticulously type pages of notes into a phone or tablet, FireSight lets the inspector simply speak out loud about what they're looking at. Using AI glasses (e.g. Meta Ray-Bans) or their cell phone, the agent can capture pictures to attach to the inspector's comments and make further observations based on the contents. The inspector can also ask the agent questions about what's been documented, what's missing, what existing records show, etc. When the inspection is done, the firefighter can export a PDF report with a single tap.

Moreover, firefighters need to make detailed observations about every nook and cranny, including places like basements, elevators, or electrical rooms that might not have great internet or cell signal. As such, we've built in an offline AI fallback. Higher-powered AI operations wait for an internet connection, while regular observations and Q&A are supported locally.

# Technical Specifications

## Cross-Platform Support
FireSight has full cross-platform mobile support via Flutter. When cross-platform dependencies are not available, use OS-specific versions of those dependencies under abstractions so that the code is easier to maintain and better designed overall.

## Basic Features

| **Feature Description** | **Implementation Details** |
| ----------------------- | -------------------------- |
| Notes are generated and photos are captured as the user speaks | Capture photos when the user starts speaking to be passed to the multimodal AI agent, which also has the context of the existing notes and tool calls to update the notes. Notes reference specific photos inline; the agent should actually receive the photos in API calls so it can understand which observations refer to which photos. |
| Pairing with Meta glasses | Use the Meta Wearables Device Access Toolkit (often referred to in this project as the Meta glasses SDK). Meta glasses integration is not a requirement to use the app; use phone camera/audio by default. The Meta glasses act like a Bluetooth speaker/microphone, so generally speaking no special SDK usage is needed to stream audio to/from the glasses, but the SDK is needed for camera access. |
| Inspection session management: users can view past inspections and load them to resume. Sessions are automatically saved as updates are made. Sessions can be exported to and imported from ZIP files. | Sessions are stored on disk as directories containing the notes (as a Markdown file) and photos, along with any relevant metadata in a JSON file. Flutter (preferred) or OS-native APIs are used for the ZIP compression/extraction and other file management utilities. |
| Audio summary of current inspection | Use on-device TTS to play a quick summary of what's been covered so far, e.g. a count of observations per category and/or regions of the building which have and haven't been covered. |
| Ask questions out loud and hear voice agent responses | When the user speaks, the agent determines if the user said a question rather than an observation, and responds if so. For example, the user may ask about what parts of the building were covered, where to get started, or any other relevant questions. The agent should leverage available context and tools to answer. 
| PDF report export - the user can tap a button to generate a PDF of the report containing the observations and corresponding photos. The PDF opens in the user's default PDF app. | Uses on-device PDF manipulation capabilities if available. Internet should not be required. |
| Building document upload - the user may have existing documents about the building (e.g. municipal documents, building plans). When internet is available, the user can upload those documents into the session and the agent can refer to them while answering user questions. | The agent should use tool calls and an on-device RAG system to query documents. A preprocessing system may be needed which converts non-Markdown documents to a condensed Markdown format. This should use a multimodal LLM like Gemini which can understand images and diagrams contained within documents. If internet is unavailable, fall back to some on-device preprocessing system (which may skip diagrams) until internet is restored. Note that Cactus specifically features document Q&A capabilities which should be used. |

## Voice Agent Architecture
The voice input/output has three layers of fallback:
1. Default: Use Gemini's voice API for voice input/output when internet is available.
2. No internet, capable device: Use Gemma 4 edge models (like E4B or E2B depending on hardware specs) via Cactus. This should be reasonably performant on recent cell phone models.
3. No internet, lower-power device: Use a suitable variant of Gemma 3 1B paired with Flutter or OS-native STT/TTS and speech detection APIs. If multimodal capabilities are unavailable based on the model, add captured photos to an internal queue to be processed by Gemini once internet is restored.
Gemini's voice API is preferred for voice input/output with on-device STT/TTS and inference as fallback when internet is not available.

## External Docs
- Meta Wearables SDK: [iOS](https://github.com/facebook/meta-wearables-dat-ios/discussions) and [Android](https://github.com/facebook/meta-wearables-dat-android) GitHub repos
- [Cactus docs homepage](https://docs.cactuscompute.com/latest/)
  - [GitHub repo](https://github.com/cactus-compute/cactus)
  - [HuggingFace](https://huggingface.co/Cactus-Compute) (includes Cactus-optimized models)
  - [Flutter SDK reference](https://docs.cactuscompute.com/latest/flutter/) and [GitHub repo](https://github.com/cactus-compute/cactus-flutter)
- [Flutter docs](https://docs.flutter.dev/)
- [Google Gemini docs](https://ai.google.dev/gemini-api/docs)
- [Google Gemma docs](https://ai.google.dev/gemma/docs)
  - [Gemma 4 models](https://ollama.com/library/gemma4)
  - [Gemma 3 1B models](https://ollama.com/library/gemma3:1b)
- [firebase_ai (Firebase AI Logic) Flutter package](https://pub.dev/packages/firebase_ai)
  - [Live API (bidirectional audio streaming) reference](https://firebase.google.com/docs/ai-logic/get-started-live-api)
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) — state management
- [go_router](https://pub.dev/packages/go_router) — declarative navigation
- [record](https://pub.dev/packages/record) — microphone recording
- [flutter_tts](https://pub.dev/packages/flutter_tts) — on-device text-to-speech
- [speech_to_text](https://pub.dev/packages/speech_to_text) — native STT (Tier 3 fallback)
- [camera](https://pub.dev/packages/camera) — phone camera access
- [archive](https://pub.dev/packages/archive) — ZIP import/export (pure Dart)
- [pdf](https://pub.dev/packages/pdf) + [printing](https://pub.dev/packages/printing) — offline PDF generation and sharing