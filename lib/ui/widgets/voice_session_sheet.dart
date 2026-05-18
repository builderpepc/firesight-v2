import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firesight/core/di.dart';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/voice/mock_voice_agent.dart';
import 'package:firesight/services/voice/voice_action.dart';
import 'package:firesight/services/voice/voice_agent.dart';
import 'package:firesight/ui/widgets/audio_visualizer.dart';
import 'package:firesight/ui/widgets/observation_editor_dialog.dart';

class VoiceMessage {
  VoiceMessage(this.text, {required this.fromUser, this.isSystem = false});
  final String text;
  final bool fromUser;
  /// System confirmation messages (e.g. "Recorded: …") shown in a muted style.
  final bool isSystem;
}

class VoiceSessionSheet extends ConsumerStatefulWidget {
  const VoiceSessionSheet({
    super.key,
    required this.agent,
    required this.session,
    required this.onSessionUpdated,
    required this.onFloorplanRequested,
    this.onStartNewInspection,
    this.onSaveRequested,
  });
  final VoiceAgent agent;
  final InspectionSession session;
  final Future<void> Function(InspectionSession) onSessionUpdated;
  final Future<void> Function() onFloorplanRequested;
  final VoidCallback? onStartNewInspection;
  final VoidCallback? onSaveRequested;

  @override
  ConsumerState<VoiceSessionSheet> createState() => _VoiceSessionSheetState();
}

class _VoiceSessionSheetState extends ConsumerState<VoiceSessionSheet> {
  final List<VoiceMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _transcriptSub;
  StreamSubscription<String>? _responseSub;
  StreamSubscription<VoiceAction>? _actionSub;
  StreamSubscription<bool>? _processingSub;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _populateMessagesFromHistory();
    _transcriptSub = widget.agent.transcriptStream.listen((text) {
      if (!mounted) return;
      setState(() {
        _messages.add(VoiceMessage(text, fromUser: true));
        _scrollToBottom();
      });
    });
    _responseSub = widget.agent.responseStream.listen((text) {
      if (!mounted) return;
      setState(() {
        _messages.add(VoiceMessage(text, fromUser: false));
        _scrollToBottom();
      });
      // History is mutated by the agent; trigger a save to persist it.
      widget.onSessionUpdated(widget.session);
    });
    _actionSub = widget.agent.actionStream.listen(_handleAction);
    _processingSub = widget.agent.processingStream.listen((processing) {
      if (!mounted) return;
      setState(() => _isProcessing = processing);
    });
    widget.agent.startListening(widget.session, widget.session.history);
  }

  void _populateMessagesFromHistory() {
    for (final turn in widget.session.history.turns) {
      _messages.add(VoiceMessage(
        turn.content == ConversationTurn.kAudioPlaceholder
            ? '🎤 [Audio]'
            : turn.content,
        fromUser: turn.role == 'user',
      ));
    }
  }

  @override
  void dispose() {
    _transcriptSub?.cancel();
    _responseSub?.cancel();
    _actionSub?.cancel();
    _processingSub?.cancel();
    _scrollController.dispose();
    widget.agent.stopListening();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleAction(VoiceAction action) async {
    switch (action) {
      case StartNewInspection():
        if (widget.onStartNewInspection != null) {
          widget.onStartNewInspection!();
        } else {
          _addSystemMessage('Starting new inspection is not available here.');
        }
      case SaveSession():
        if (widget.onSaveRequested != null) {
          widget.onSaveRequested!();
        } else {
          _addSystemMessage('Saving is not available here.');
        }
      case RecordObservation(:final text):
        await _persistObservation(text: text);
      case TakePhoto(:final description):
        await _takePhotoObservation(description: description);
      case UploadFloorplan():
        await widget.onFloorplanRequested();
    }
  }

  void _addSystemMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(VoiceMessage(text, fromUser: false, isSystem: true));
      _scrollToBottom();
    });
  }

  void _showCheatSheet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Commands'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• "New inspection" - Start a new survey'),
            Text('• "Save session" - Save current work'),
            Text('• "Upload floorplan" - Add building map'),
            Text('• "Take a photo" - Open camera'),
            Text('• "Record [observation]" - Save a note'),
            SizedBox(height: 12),
            Text('Tip: You can just talk naturally! The AI understands context.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _persistObservation({
    required String text,
    String? category,
    String? photoPath,
  }) async {
    final observation = Observation(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      text: text,
      category: category,
      photoFileRef: photoPath,
    );
    final updated = widget.session.copyWith(
      observations: [...widget.session.observations, observation],
    );
    await widget.onSessionUpdated(updated);
    if (!mounted) return;
    setState(() {
      _messages.add(
        VoiceMessage('Recorded: "$text"', fromUser: false, isSystem: true),
      );
      _scrollToBottom();
    });
  }

  Future<void> _takePhotoObservation({String? description}) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null || !mounted) return;

    await showDialog(
      context: context,
      builder: (context) => ObservationEditorDialog(
        initialText: description,
        initialPhotoPath: photo.path,
        onSave: (text, category, photoPath) async {
          Navigator.pop(context);
          final service = await ref.read(sessionServiceProvider.future);
          final permanentPath = photoPath != null 
              ? await service.saveImage(photoPath) 
              : null;
              
          await _persistObservation(
            text: text,
            category: category,
            photoPath: permanentPath,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mock = widget.agent is MockVoiceAgent
        ? widget.agent as MockVoiceAgent
        : null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.mic),
                  const SizedBox(width: 8),
                  Text(
                    'Voice Agent',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: _showCheatSheet,
                    tooltip: 'Voice Commands Help',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            AudioVisualizer(
              audioLevelStream: widget.agent.audioLevelStream,
              isProcessing: _isProcessing,
            ),
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI is thinking...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 480),
              child: _messages.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Listening…',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        if (m.isSystem) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Center(
                              child: Text(
                                m.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                          );
                        }
                        return Align(
                          alignment: m.fromUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: m.fromUser
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(m.text),
                          ),
                        );
                      },
                    ),
            ),
            if (kDebugMode && mock != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Demo: new inspection'),
                      onPressed: () => mock.simulateCommand('new inspection'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Demo: save session'),
                      onPressed: () => mock.simulateCommand('save session'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Demo: upload floorplan'),
                      onPressed: () => mock.simulateCommand('upload floorplan'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.push_pin_outlined),
                      label: const Text('Demo: mark asset'),
                      onPressed: () => mock.simulateCommand('mark asset'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Demo: take photo'),
                      onPressed: () => mock.simulateCommand('take photo'),
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
