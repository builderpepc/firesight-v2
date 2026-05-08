import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firesight/core/di.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_agent.dart';

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

  final List<_LogEntry> _transcripts = [];
  final List<_LogEntry> _responses = [];
  StreamSubscription<String>? _transcriptSub;
  StreamSubscription<String>? _responseSub;
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
    // Eagerly resolve current state.
    connectivity.checkOnline().then((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  Future<void> _startListening() async {
    setState(() {
      _errorMessage = null;
      _tierLabel = 'Resolving…';
    });

    try {
      final service = ref.read(voiceAgentServiceProvider);
      final agent = await service.resolveAgent();

      // Use a throwaway in-memory session so disk is not polluted.
      final session = InspectionSession(
        id: 'debug-session',
        name: 'Debug Session',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await agent.startListening(session);

      _transcriptSub = agent.transcriptStream.listen((text) {
        if (mounted) {
          setState(() => _transcripts.add(_LogEntry(text)));
        }
      });

      _responseSub = agent.responseStream.listen((text) {
        if (mounted) {
          setState(() => _responses.add(_LogEntry(text)));
        }
        // Play response aloud.
        ref.read(ttsServiceProvider).speak(text);
      });

      if (mounted) {
        setState(() {
          _agent = agent;
          _isListening = true;
          _tierLabel = 'Tier 1 — Gemini';
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
    await _transcriptSub?.cancel();
    await _responseSub?.cancel();
    await _agent?.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
        _tierLabel = 'Idle';
      });
    }
  }

  @override
  void dispose() {
    _onlineSub?.cancel();
    _transcriptSub?.cancel();
    _responseSub?.cancel();
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
            if (_errorMessage != null)
              _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 12),
            _ControlButton(
              isListening: _isListening,
              enabled: _isOnline && !_isListening || _isListening,
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
                ? const Center(child: Text('—', style: TextStyle(color: Colors.grey)))
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
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}

class _LogEntry {
  _LogEntry(this.text) : timestamp = DateTime.now();

  final String text;
  final DateTime timestamp;
}
