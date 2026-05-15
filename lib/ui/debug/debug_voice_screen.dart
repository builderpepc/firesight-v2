import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firesight/core/di.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/cactus_voice_agent.dart';
import 'package:firesight/services/voice/gemini_voice_agent.dart';
import 'package:firesight/services/voice/native_fallback_agent.dart';
import 'package:firesight/services/voice/voice_agent.dart';

enum _TierOverride {
  auto('Auto (connectivity-based)'),
  tier1('Tier 1 — Gemini (online)'),
  tier2e2b('Tier 2 — Gemma 4 E2B (Cactus)'),
  tier2e4b('Tier 2 — Gemma 4 E4B (Cactus)'),
  tier3('Tier 3 — Gemma 3 1B (native STT/TTS)');

  const _TierOverride(this.label);
  final String label;
}

/// Throwaway debug screen for testing the voice agent pipeline.
///
/// Navigate to this screen via /debug/voice during development.
/// It is NOT linked from the production UI.
class DebugVoiceScreen extends ConsumerStatefulWidget {
  const DebugVoiceScreen({super.key});

  @override
  ConsumerState<DebugVoiceScreen> createState() => _DebugVoiceScreenState();
}

class _DebugVoiceScreenState extends ConsumerState<DebugVoiceScreen> {
  VoiceAgent? _agent;
  bool _isListening = false;
  bool _isOnline = false;
  String _tierLabel = 'Unknown';
  String? _errorMessage;
  _TierOverride _tierOverride = _TierOverride.auto;

  final List<_LogEntry> _transcripts = [];
  final List<_LogEntry> _responses = [];
  StreamSubscription<String>? _transcriptSub;
  StreamSubscription<String>? _responseSub;
  StreamSubscription<Object>? _errorSub;
  StreamSubscription<bool>? _onlineSub;

  @override
  void initState() {
    super.initState();
    _subscribeToConnectivity();
  }

  void _subscribeToConnectivity() {
    final connectivity = ref.read(connectivityServiceProvider);
    _onlineSub = connectivity.isOnline.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
    connectivity.checkOnline().then((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  /// Resolves an agent according to [_tierOverride], bypassing connectivity
  /// checks when a specific tier is forced.
  Future<VoiceAgent> _resolveAgent() async {
    switch (_tierOverride) {
      case _TierOverride.auto:
        return ref.read(voiceAgentServiceProvider).resolveAgent();
      case _TierOverride.tier1:
        return GeminiVoiceAgent(
          ref.read(firebaseAIProvider),
          ref.read(audioOutputServiceProvider),
        );
      case _TierOverride.tier2e2b:
        final path = await CactusVoiceAgent.defaultModelPath(kGemma4E2bSlug);
        return CactusVoiceAgent(path, ref.read(sttProvider), ref.read(ttsProvider));
      case _TierOverride.tier2e4b:
        final path = await CactusVoiceAgent.defaultModelPath(kGemma4E4bSlug);
        return CactusVoiceAgent(path, ref.read(sttProvider), ref.read(ttsProvider));
      case _TierOverride.tier3:
        return NativeFallbackAgent(ref.read(sttProvider), ref.read(ttsProvider));
    }
  }

  String _labelForAgent(VoiceAgent agent) {
    if (agent is GeminiVoiceAgent) return 'Tier 1 — Gemini';
    if (agent is CactusVoiceAgent) {
      final variant = agent.modelSlug == kGemma4E4bSlug ? 'E4B' : 'E2B';
      return 'Tier 2 — Gemma 4 $variant (Cactus)';
    }
    if (agent is NativeFallbackAgent) return 'Tier 3 — Native STT/TTS';
    return 'Unknown';
  }

  Future<void> _startListening() async {
    setState(() {
      _errorMessage = null;
      _tierLabel = 'Resolving…';
    });

    try {
      final agent = await _resolveAgent();

      final session = InspectionSession(
        id: 'debug-session',
        name: 'Debug Session',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _transcriptSub = agent.transcriptStream.listen((text) {
        if (mounted) setState(() => _transcripts.add(_LogEntry(text)));
      });
      _responseSub = agent.responseStream.listen((text) {
        if (mounted) setState(() => _responses.add(_LogEntry(text)));
      });
      _errorSub = agent.errorStream.listen((error) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _tierLabel = 'Error';
            _errorMessage = error.toString();
          });
        }
      });

      await agent.startListening(session);

      if (mounted) {
        setState(() {
          _agent = agent;
          _isListening = true;
          _tierLabel = _labelForAgent(agent);
        });
      }
    } on UnimplementedError catch (e) {
      if (mounted) {
        setState(() {
          _tierLabel = 'Unavailable';
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tierLabel = 'Error';
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _stopListening() async {
    if (mounted) {
      setState(() {
        _isListening = false;
        _tierLabel = 'Idle';
      });
    }
    await _transcriptSub?.cancel();
    await _responseSub?.cancel();
    await _errorSub?.cancel();
    _agent?.stopListening();
  }

  bool get _canStart {
    if (_isListening) return false;
    // Auto mode requires connectivity; forced overrides work regardless.
    if (_tierOverride == _TierOverride.auto) return _isOnline;
    return true;
  }

  @override
  void dispose() {
    _onlineSub?.cancel();
    _transcriptSub?.cancel();
    _responseSub?.cancel();
    _errorSub?.cancel();
    _agent?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Agent Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRow(isOnline: _isOnline, tierLabel: _tierLabel),
            const SizedBox(height: 12),
            _TierOverrideDropdown(
              value: _tierOverride,
              enabled: !_isListening,
              onChanged: (v) => setState(() => _tierOverride = v),
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 12),
            _ControlButton(
              isListening: _isListening,
              enabled: _canStart || _isListening,
              onStart: _startListening,
              onStop: _stopListening,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LogPanel(label: 'Transcript', entries: _transcripts),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LogPanel(label: 'Responses', entries: _responses),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierOverrideDropdown extends StatelessWidget {
  const _TierOverrideDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final _TierOverride value;
  final bool enabled;
  final ValueChanged<_TierOverride> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<_TierOverride>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Voice tier override',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: _TierOverride.values
          .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
          .toList(),
      onChanged: enabled ? (v) { if (v != null) onChanged(v); } : null,
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.isOnline, required this.tierLabel});

  final bool isOnline;
  final String tierLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Chip(
          avatar: Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: isOnline ? Colors.green : Colors.red,
          ),
          label: Text(isOnline ? 'Online' : 'Offline'),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(tierLabel),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.isListening,
    required this.enabled,
    required this.onStart,
    required this.onStop,
  });

  final bool isListening;
  final bool enabled;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? (isListening ? onStop : onStart) : null,
      icon: Icon(isListening ? Icons.stop : Icons.mic),
      label: Text(isListening ? 'Stop' : 'Start Listening'),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.label, required this.entries});

  final String label;
  final List<_LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: entries.isEmpty
                ? const Center(
                    child: Text('—', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(e.timestamp),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(e.text),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';
}

class _LogEntry {
  _LogEntry(this.text) : timestamp = DateTime.now();

  final String text;
  final DateTime timestamp;
}
