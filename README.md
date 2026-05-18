# FireSight

Voice automation for fire department pre-incident inspections.

FireSight is a Flutter app for capturing inspection observations by voice, attaching photos, saving
inspection sessions locally, and exporting reports. The app is designed for mobile use with online
Gemini support and offline fallbacks.

## The Problem We Solve

Fire departments - the real firefighters themselves, not (just) city officials - have to spend countless hours every year performing inspections on buildings called pre-incident surveys. The purpose of these inspections is to assess risk and strategize for potential emergencies. For high-risk buildings like hospitals or schools, these inspections can happen multiple times per year. As part of these inspections, firefighters need to record countless data points in outdated, clunky web forms or even on paper. Moreover, sometimes the sites are remote or shielded from internet connection.

We spoke to real industry professionals and firefighters at departments like FDNY and Colonia for feedback and insights. There's a real need here, and we built a better solution with the technology available to us today for a better tomorrow for global fire resilience.

## How Our Project Works

Rather than making firefighters meticulously type pages of notes into a phone or tablet, FireSight lets the inspector simply speak out loud about what they're looking at. Using AI glasses (e.g. Meta Ray-Bans), the agent can capture pictures to attach to the inspector's comments and make further observations based on the contents. The inspector can also ask the agent questions about what's been documented, what's missing, what existing records show, etc. When the inspection is done, the firefighter can export a PDF report with a single tap.

Moreover, firefighters need to make detailed observations about every nook and cranny, including places like basements, elevators, or electrical rooms that might not have great internet or cell signal. As such, we've built in an offline AI fallback. Higher-powered AI operations wait for an internet connection, while regular observations and Q&A are supported locally.

# Technical details

## Current MVP Features

- Create and resume local inspection sessions.
- Capture inspection observations as notes and photo-linked floorplan pins.
- Auto-fill a structured FireSight inspection form from saved observations.
- Review and edit auto-filled form fields before export.
- Generate and share an offline PDF report from the structured form and raw observations.

The current form autofill MVP uses a local rule-based engine with heuristic confidence scores. The
autofill service is intentionally behind the `FormAutofillEngine` interface so future Cactus or
Gemini engines can replace or augment the rule-based implementation without changing the form UI or
PDF export path.

## FireSight — Design Architecture

FireSight is a Flutter mobile app for fire department pre-incident inspections.
Inspectors speak observations out loud; an AI voice agent captures notes, attaches
photos, answers questions about what's been documented, and produces a structured
PDF report. The architecture is designed around three constraints baked into the
problem domain:

1. **Offline-first** — basements, electrical rooms, and stairwells have no signal.
2. **Cross-platform** — iOS + Android from a single codebase.
3. **Source-agnostic data** — observations may originate from voice, manual notes,
   or floorplan-pin photos, and the rest of the pipeline (autofill, PDF, history)
   doesn't care which.

---

### 1. Layered architecture

```
┌────────────────────────────────────────────────────────────────┐
│ UI layer            lib/ui/                                    │
│   home_screen.dart, inspection_screen.dart, widgets/, debug/   │
└────────────────────────────────────────────────────────────────┘
                              ▲
                              │ Riverpod providers
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ Composition / DI    lib/core/di.dart                           │
│   Single file declaring every provider in the app.             │
└────────────────────────────────────────────────────────────────┘
                              ▲
                              │ constructor injection
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ Services            lib/services/                              │
│   voice/  forms/  session/  pdf/  model/  camera/  audio/      │
│   tts/    connectivity/  device/  documents/                   │
└────────────────────────────────────────────────────────────────┘
                              ▲
                              │ plain data
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ Models              lib/models/                                │
│   InspectionSession, Observation, InspectionForm,              │
│   ConversationHistory, BuildingDocument, SessionMetadata,      │
│   FormFieldSuggestion (+ json_serializable .g.dart files)      │
└────────────────────────────────────────────────────────────────┘
```

Models hold no behaviour beyond JSON (de)serialization and `copyWith`. Services
hold all logic and are stateless from the UI's perspective — they are reached
through Riverpod providers, never instantiated directly.

---

### 2. Composition root — `lib/core/di.dart`

All wiring lives in a single file. Each provider declares one piece of the
system; the UI watches providers, and providers compose other providers. There
are no service locators, no singletons outside of Riverpod, and no global state.

Key providers and their roles:

| Provider | Role |
|----------|------|
| `appDocsDirProvider` | Resolves the app documents directory once at startup. Everything file-backed depends on this. |
| `sessionStorageProvider` | `LocalSessionStorage` — file layout on disk. |
| `sessionServiceProvider` | CRUD operations over sessions. |
| `sessionsProvider` | Stream of session metadata for the home screen. |
| `sessionExportProvider` | ZIP import/export. |
| `connectivityServiceProvider` / `isOnlineProvider` | Interface-level reachability. **Caveat:** reports network interface state, not true internet (captive portals fool it). |
| `voiceAgentServiceProvider` | Tier selector for the voice subsystem (see §4). |
| `formAutofillEngineProvider` / `formAutofillServiceProvider` | Pluggable autofill engine (see §5). |
| `pdfExportServiceProvider` | Offline PDF generation. |
| `modelDownloadProvider` | `StateNotifier` driving the Gemma 4 download lifecycle. |
| `cameraProviderProvider` | Phone camera by default; Meta Glasses provider behind the same interface. |

The Riverpod 3 split between `Provider`, `FutureProvider`, and
`StateNotifierProvider` is intentional: async-resolved resources (filesystem,
model download) use `FutureProvider`; stateful side effects use
`StateNotifierProvider`; everything else is a plain `Provider`.

---

### 3. Session and storage model

#### Domain model

```
InspectionSession
├── id, name, createdAt, updatedAt
├── observations:        List<Observation>
├── buildingDocuments:   List<BuildingDocument>
├── history:             ConversationHistory     (voice-agent turns)
├── floorplanPath, zipCode, buildingType
├── inspectorId, status, riskLevel
├── form:                InspectionForm          (structured fields)
└── formSuggestions:     List<FormFieldSuggestion>
```

`Observation` is the atomic unit — text, optional photo, optional `(x, y)` pin
on the floorplan, optional category, timestamp. Every downstream consumer
(autofill, PDF, history view) reads from this list.

#### On-disk layout (`LocalSessionStorage`)

```
<app docs>/
  sessions/
    index.json                ← lightweight metadata for the home screen list
    <session-id>/
      session.json            ← serialized InspectionSession
      photos/
        <uuid>.jpg
      documents/
        <uuid>.pdf            ← uploaded building documents
```

This split keeps the home screen fast (read one small JSON) and isolates per-
session blobs so a session can be ZIP-exported as a directory tree.

`SessionExport` handles `.firesight.zip` import/export via the pure-Dart
`archive` package — chosen over platform-native ZIP APIs for cross-platform
consistency.

---

### 4. Voice agent subsystem

The voice agent is the heart of the product. It is structured as a **strategy
pattern with runtime tier selection** so the UI is identical regardless of
which underlying engine is active.

#### Interface

`lib/services/voice/voice_agent.dart` defines the contract every tier
implements:

```dart
abstract class VoiceAgent {
  Future<void> startListening(InspectionSession session, ConversationHistory history);
  Future<void> stopListening();

  Stream<String>      get transcriptStream;   // user speech
  Stream<String>      get responseStream;     // agent text (for TTS playback)
  Stream<bool>        get processingStream;   // drives loading indicator
  Stream<Object>      get errorStream;        // fatal errors → reset UI
  Stream<VoiceAction> get actionStream;       // RecordObservation, TakePhoto, …
  Stream<double>      get audioLevelStream;   // 0.0–1.0 for visualizer
  Future<void>        dispose();
}
```

The UI subscribes to streams and dispatches `VoiceAction` instances. The agent
never touches the session directly — it only emits *intents*, which keeps tier
implementations simple and the UI in control of persistence.

#### Tier selection (`VoiceAgentService.resolveAgent`)

| Tier | Trigger | Implementation | Backed by |
|------|---------|----------------|-----------|
| 1    | Internet available | `GeminiVoiceAgent` | Firebase AI Live API (bidirectional audio streaming) + SoLoud for PCM playback |
| 2    | Offline, ≥ 6 GB RAM | `CactusVoiceAgent` (E4B) | Cactus FFI + Gemma 4 E4B + native STT/TTS |
| 2    | Offline, 4–6 GB RAM | `CactusVoiceAgent` (E2B) | Cactus FFI + Gemma 4 E2B + native STT/TTS |
| 3    | Offline, < 4 GB RAM | `NativeFallbackAgent` | `speech_to_text` + `flutter_tts` + (planned) Gemma 3 1B |

Thresholds live as constants in `voice_agent_service.dart`. A `MockVoiceAgent`
exists for tests and the debug screen.

#### Cactus integration

`lib/cactus.dart` is hand-written FFI bindings against `libcactus.so` (Android
arm64-v8a, ~1200 lines, source-integrated rather than via the deprecated
`cactus-flutter` pub package). The compiled `.so` lives under
`android/app/src/main/jniLibs/arm64-v8a/`. iOS support requires CocoaPods and
deployment target ≥ 16.0 because Cactus 1.3+ pulls in iOS-16-only frameworks.

#### Conversation continuity

`ConversationHistory` is a *mutable* object shared across agent instances. When
the device drops offline mid-session, the UI swaps the Tier 1 agent for a
Tier 2 agent and passes the same `ConversationHistory` instance — the new
agent reads prior turns from it and continues without losing context.

#### Model download (`ModelDownloadService`)

Gemma 4 weights (~4 GB) are downloaded on first launch via `dio` with progress
streaming. The download runs inside a `flutter_foreground_task` service so it
survives the screen turning off. Extracted weights land under
`<app docs>/cactus/<slug>/`.

---

### 5. Form autofill subsystem

The form autofill path is intentionally pluggable so the rule-based MVP can be
swapped for a Cactus or Gemini engine without UI changes.

```
InspectionSession.observations
        → FormAutofillService
        → FormAutofillEngine            (interface)
        → InspectionForm + FormFieldSuggestion[]   (confidence + evidence)
        → PdfExportService
```

The current engine is `RuleBasedFormAutofillEngine` — keyword and phrase
matching against the `InspectionFormFieldIds` schema, with fixed confidence
heuristics. Future engines must return the same `FormAutofillResult` shape;
the UI swaps engines by reassigning `formAutofillEngineProvider` in `di.dart`.

`FormFieldSuggestion` carries `fieldId`, `value`, `confidence`, `evidence`, and
`source`, so the review UI can show *why* each suggestion appeared.

---

### 6. Camera and Meta Glasses

`CameraProvider` is an interface with two implementations:

- `PhoneCameraProvider` — uses the `camera` / `image_picker` packages.
- `MetaGlassesProvider` — uses `meta_wearables_dat` (Meta Wearables Device
  Access Toolkit). Currently returns `isAvailable = false` until the SDK
  conflict is resolved; the plumbing is in place behind the interface.

The Meta glasses act like a Bluetooth speaker/microphone for audio (no special
SDK needed for streaming), so only camera access is brokered through the
Meta SDK.

---

### 7. PDF export

`PdfExportService` uses `pdf` + `printing` for fully offline generation. It
reads from the structured `InspectionForm` plus the `Observation` list, embeds
photos by path, and hands the result to the platform share sheet via
`printing`. No network is required and no document is uploaded anywhere.

---

### 8. Routing and UI

- **Routing**: `go_router` (declarative). The router config lives in
  `lib/core/router.dart` and is wired in `lib/main.dart`.
- **State management**: `flutter_riverpod` 3.x. Screens are `ConsumerWidget`
  / `ConsumerStatefulWidget`; the UI watches providers and never reaches into
  service instances directly.
- **Screens**:
  - `HomeScreen` — list of past sessions, "new inspection" action.
  - `InspectionScreen` — main editor: session details card, floorplan with
    pinned observations, observation list, voice button, form/PDF actions.
  - `DebugVoiceScreen` (under `ui/debug/`) — engineer-facing test surface
    for each voice tier independently.

#### Reusable widgets (`lib/ui/widgets/`)

- `FloorplanViewer` — `InteractiveViewer` + `Image.file` + overlay pins
  positioned in normalized image coordinates so portrait/landscape mismatches
  don't shift pins.
- `ObservationEditorDialog` — shared create/edit form for observations
  (text, category, photo).
- `VoiceSessionSheet` — modal bottom sheet hosting an active voice agent
  session: transcript log, audio visualizer, processing indicator.
- `AudioVisualizer` — animated amplitude bars fed by `audioLevelStream`.

---

### 9. Cross-platform notes

- **iOS**: deployment target 16.0 (Cactus requirement). The repo's `.lldbinit`
  auto-continues past `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` breakpoints, which fire
  during normal Flutter VM operation.
- **Android**: `libcactus.so` is checked in under `jniLibs/arm64-v8a/`. A
  foreground service handles the model download lifecycle. The
  `EmojiCompatInitializer` missing-class warning is suppressed at launch.
- **Both**: anything platform-specific sits behind an interface in `services/`
  with a stub fallback so the rest of the app compiles even when one platform
  is incomplete.

---

### 10. Key design decisions and their rationale

| Decision | Why |
|----------|-----|
| Voice agent is an interface with streamed `VoiceAction` intents | Lets UI persistence stay in one place; tiers are easy to add/swap. |
| `ConversationHistory` is mutable and external to agents | Survives tier swaps and stop/restart cycles without serialization round-trips. |
| Form autofill engine is a pluggable interface | MVP ships with rules today; Cactus/Gemini engines drop in without UI changes. |
| File-based session storage (one dir per session) | Photos and documents stay with their session; ZIP export is just `zip -r`. |
| Riverpod for everything | Async resources, mutable state, and pure services share one mental model. |
| All DI in a single `di.dart` | Easy to audit the entire dependency graph; no hunting for registrations. |
| Pure-Dart `archive` over native ZIP APIs | Cross-platform consistency at the cost of a small perf hit. |
| Hand-written Cactus FFI bindings | The pub.dev `cactus-flutter` package is deprecated; source integration tracks upstream. |

---

### 11. Where to look first

| Topic | Start here |
|-------|------------|
| App entry & Firebase init | `lib/main.dart` |
| Provider graph | `lib/core/di.dart` |
| Routing | `lib/core/router.dart` |
| Voice tier selection | `lib/services/voice/voice_agent_service.dart` |
| Voice agent contract | `lib/services/voice/voice_agent.dart` |
| Session persistence | `lib/services/session/local_session_storage.dart` |
| Autofill pipeline | `lib/services/forms/form_autofill_service.dart` |
| Main editing screen | `lib/ui/inspection_screen.dart` |
| Floorplan rendering | `lib/ui/widgets/floorplan_viewer.dart` |
| External docs and product context | `PROJECT.md` |


## Setup

This project is designed to be set up with the help of a coding agent (e.g. Claude Code). Open the
project in your agent, ask it to set up the project, and it will auto-discover the project context
and setup skill in `.agents/skills/firesight-setup/` and guide you through the full process.
