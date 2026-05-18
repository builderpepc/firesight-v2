import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firesight/core/di.dart';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_form.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/voice/mock_voice_agent.dart';
import 'package:firesight/services/voice/voice_action.dart';
import 'package:firesight/services/voice/voice_agent.dart';
import 'package:firesight/ui/widgets/floorplan_viewer.dart';

class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({super.key, this.sessionId});
  final String? sessionId;

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  InspectionSession? _session;
  bool _isLoading = true;
  bool _pinModeEnabled = false;
  bool _isAutofilling = false;
  late final TextEditingController _nameController;
  late final TextEditingController _inspectorController;
  late final Map<String, TextEditingController> _formControllers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _inspectorController = TextEditingController();
    _formControllers = {
      for (final config in _fieldConfigs)
        config.fieldId: TextEditingController(),
    };
    if (widget.sessionId == null) {
      // New session: construct in-memory only; persist on first save so back
      // navigation without saving leaves no orphan row.
      final now = DateTime.now();
      _session = InspectionSession(
        id: const Uuid().v4(),
        name: 'New Inspection ${now.toLocal()}',
        createdAt: now,
        updatedAt: now,
      );
      _isLoading = false;
      _nameController.text = _session!.name;
    } else {
      _loadExistingSession();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _inspectorController.dispose();
    for (final controller in _formControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingSession() async {
    final service = await ref.read(sessionServiceProvider.future);
    final session = await service.loadSession(widget.sessionId!);
    if (!mounted) return;
    setState(() {
      _session = session;
      _isLoading = false;
    });
    _syncControllersFromSession();
  }

  Future<void> _pickFloorplan() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && _session != null) {
      final service = await ref.read(sessionServiceProvider.future);
      final permanentPath = await service.saveImage(image.path);
      final updatedSession = _session!.copyWith(floorplanPath: permanentPath);
      await _persistSession(updatedSession);
      setState(() {});
    }
  }

  Future<void> _saveSession() async {
    if (_session == null) return;

    try {
      final updatedSession = _session!.copyWith(
        name: _nameController.text.trim().isEmpty
            ? _session!.name
            : _nameController.text.trim(),
        inspectorId: _normalizedText(_inspectorController.text),
        form: _formFromControllers(),
      );
      await _persistSession(updatedSession);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save inspection: $e')),
        );
      }
    }
  }

  Future<void> _addObservationAt(double x, double y) async {
    if (_session == null) return;

    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    final noteController = TextEditingController();

    if (!mounted) return;

    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note to Picture'),
        content: TextField(
          controller: noteController,
          decoration:
              const InputDecoration(hintText: 'Enter observation details...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    noteController.dispose();

    if (note != null) {
      final service = await ref.read(sessionServiceProvider.future);
      final permanentPath = await service.saveImage(photo.path);

      final observation = Observation(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        text: note,
        photoFileRef: permanentPath,
        floorplanX: x,
        floorplanY: y,
      );

      final updatedSession = _session!.copyWith(
        observations: [..._session!.observations, observation],
      );

      await _persistSession(updatedSession);
      setState(() {});
    }
  }

  Future<void> _addNoteOnlyObservation() async {
    if (_session == null) return;

    final note = await _showObservationEditorDialog();
    if (note == null) {
      return;
    }

    final observation = Observation(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      text: note,
    );

    final updatedSession = _session!.copyWith(
      observations: [..._session!.observations, observation],
    );

    await _persistSession(updatedSession);
    setState(() {});
  }

  Future<void> _openVoiceSession() async {
    if (_session == null) return;

    final voiceService = ref.read(voiceAgentServiceProvider);
    final VoiceAgent agent;
    try {
      agent = await voiceService.resolveAgent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice agent unavailable: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VoiceSessionSheet(
        agent: agent,
        session: _session!,
        onSessionUpdated: (updated) async {
          await _persistSession(updated);
          if (mounted) setState(() {});
        },
        onFloorplanRequested: _pickFloorplan,
      ),
    );
  }

  Future<void> _openFocusedFloorplan() async {
    if (_session?.floorplanPath == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatefulBuilder(
          builder: (context, setLocalState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Floorplan Focus'),
                actions: [
                  IconButton(
                    icon: Icon(_pinModeEnabled
                        ? Icons.add_location_alt
                        : Icons.add_location_alt_outlined),
                    tooltip: _pinModeEnabled
                        ? 'Exit pin placement mode'
                        : 'Enter pin placement mode',
                    onPressed: () => setLocalState(() {
                      _pinModeEnabled = !_pinModeEnabled;
                    }),
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        _pinModeEnabled
                            ? 'Pin mode: tap the floorplan to add a photo note.'
                            : 'Pinch to zoom and drag to pan. Tap a pin to view its note. '
                                'Tap the location icon to enter pin placement mode.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: FloorplanViewer(
                            floorplanPath: _session!.floorplanPath!,
                            observations: _session!.observations,
                            pinPlacementMode: _pinModeEnabled,
                            onTap: (x, y) async {
                              await _addObservationAt(x, y);
                              if (mounted) {
                                setLocalState(() {});
                              }
                            },
                            onObservationTap: _showObservationDetails,
                            minScale: 0.8,
                            maxScale: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showObservationDetails(Observation observation) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observation Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (observation.photoFileRef != null)
                Image.file(File(observation.photoFileRef!)),
              const SizedBox(height: 16),
              const Text('Note:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(observation.text ?? 'No note added'),
              const SizedBox(height: 8),
              Text(
                'Taken at: ${observation.timestamp.toLocal()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _editObservation(observation);
            },
            child: const Text('Edit Note'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _editObservation(Observation observation) async {
    if (_session == null) return;

    final updatedNote = await _showObservationEditorDialog(
      initialValue: observation.text ?? '',
      title: 'Edit Note',
      actionLabel: 'Update',
    );
    if (updatedNote == null) {
      return;
    }

    final updatedObservation = Observation(
      id: observation.id,
      timestamp: observation.timestamp,
      text: updatedNote,
      photoFileRef: observation.photoFileRef,
      response: observation.response,
      floorplanX: observation.floorplanX,
      floorplanY: observation.floorplanY,
    );

    final updatedSession = _session!.copyWith(
      observations: _session!.observations
          .map((item) => item.id == observation.id ? updatedObservation : item)
          .toList(),
    );

    await _persistSession(updatedSession);
    setState(() {});
  }

  Future<String?> _showObservationEditorDialog({
    String initialValue = '',
    String title = 'Add Note',
    String actionLabel = 'Save',
  }) async {
    final noteController = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: noteController,
          decoration:
              const InputDecoration(hintText: 'Enter observation details...'),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, noteController.text.trim()),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (result == null) {
      return null;
    }

    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Failed to load session')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_session!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _openVoiceSession,
            tooltip: 'Voice Agent',
          ),
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: _openInspectionForm,
            tooltip: 'Inspection Form',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSession,
            tooltip: 'Save Inspection',
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _pickFloorplan,
            tooltip: 'Add Floorplan',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSessionDetailsCard(),
            ),
            Expanded(
              child: _session!.floorplanPath == null
                  ? _buildNoFloorplanState()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: _openFocusedFloorplan,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              FloorplanViewer(
                                floorplanPath: _session!.floorplanPath!,
                                observations: _session!.observations,
                                onObservationTap: _showObservationDetails,
                              ),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_out_map,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Tap to focus',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildObservationHistory(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _saveSession();
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        icon: const Icon(Icons.check),
        label: const Text('Save & Exit'),
      ),
    );
  }

  Future<void> _openInspectionForm() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85 -
              MediaQuery.of(context).viewInsets.bottom,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildInspectionFormCard(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _persistSession(InspectionSession session) async {
    final service = await ref.read(sessionServiceProvider.future);
    final sessionToSave = session.copyWith(updatedAt: DateTime.now());
    await service.saveSession(sessionToSave);
    _session = sessionToSave;
  }

  void _syncControllersFromSession() {
    final session = _session;
    if (session == null) return;
    _nameController.text = session.name;
    _inspectorController.text = session.inspectorId ?? '';
    _syncControllersFromForm(session.form);
  }

  String? _normalizedText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildSessionDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Session Name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inspectorController,
              decoration: const InputDecoration(
                labelText: 'Inspector',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Updated: ${_session!.updatedAt.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFloorplanState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.layers_clear,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No floorplan added'),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickFloorplan,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Floorplan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _autofillForm() async {
    if (_session == null || _isAutofilling) return;
    setState(() => _isAutofilling = true);
    try {
      _syncSessionFormFromControllers();
      final service = ref.read(formAutofillServiceProvider);
      final result = await service.autofill(
        currentForm: _session!.form,
        observations: _session!.observations,
      );

      // Merge suggestions by fieldId so repeated autofill runs don't accumulate
      // duplicates — the newest suggestion for each field wins.
      final mergedSuggestions = {
        for (final s in [
          ..._session!.formSuggestions,
          ...result.suggestions,
        ])
          s.fieldId: s,
      }.values.toList();

      final updatedSession = _session!.copyWith(
        form: result.form,
        formSuggestions: mergedSuggestions,
      );

      await _persistSession(updatedSession);
      if (!mounted) return;
      setState(() {
        _syncControllersFromForm(result.form);
      });
    } finally {
      if (mounted) setState(() => _isAutofilling = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_session == null) return;
    _syncSessionFormFromControllers();
    try {
      await ref.read(pdfExportServiceProvider).generateAndShare(_session!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    }
  }

  void _syncSessionFormFromControllers() {
    if (_session == null) return;
    _session = _session!.copyWith(form: _formFromControllers());
  }

  InspectionForm _formFromControllers() {
    return InspectionForm(
      buildingName: _textFor(InspectionFormFieldIds.buildingName),
      address: _textFor(InspectionFormFieldIds.address),
      occupancyType: _textFor(InspectionFormFieldIds.occupancyType),
      constructionType: _textFor(InspectionFormFieldIds.constructionType),
      alarmPanelLocation: _textFor(InspectionFormFieldIds.alarmPanelLocation),
      sprinklerRiserLocation: _textFor(
        InspectionFormFieldIds.sprinklerRiserLocation,
      ),
      fireProtectionSystems: _textFor(
        InspectionFormFieldIds.fireProtectionSystems,
      ),
      utilityShutoffs: _textFor(InspectionFormFieldIds.utilityShutoffs),
      hazards: _textFor(InspectionFormFieldIds.hazards),
      accessNotes: _textFor(InspectionFormFieldIds.accessNotes),
      notes: _textFor(InspectionFormFieldIds.notes),
    );
  }

  String? _textFor(String fieldId) {
    final text = _formControllers[fieldId]?.text.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  void _syncControllersFromForm(InspectionForm form) {
    for (final config in _fieldConfigs) {
      _formControllers[config.fieldId]?.text =
          form.valueFor(config.fieldId) ?? '';
    }
  }

  String _labelFor(String fieldId) {
    return _fieldConfigs
        .firstWhere(
          (config) => config.fieldId == fieldId,
          orElse: () => _FormFieldConfig(fieldId, fieldId),
        )
        .label;
  }

  Widget _buildInspectionFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Inspection Form',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      (_session!.observations.isEmpty || _isAutofilling) ? null : _autofillForm,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Autofill'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ..._fieldConfigs.map(
                    (config) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _formControllers[config.fieldId],
                        maxLines: config.maxLines,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: config.label,
                        ),
                        onChanged: (_) => _syncSessionFormFromControllers(),
                      ),
                    ),
                  ),
                  if (_session!.formSuggestions.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      'Autofill suggestions',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ..._session!.formSuggestions.map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${_labelFor(suggestion.fieldId)}: '
                          '${(suggestion.confidence * 100).round()}% confidence',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationHistory() {
    final observations = [..._session!.observations]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Saved Observations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNoteOnlyObservation,
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Add Note'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (observations.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No saved notes or photos yet'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: observations.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final observation = observations[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: observation.photoFileRef == null
                          ? const CircleAvatar(child: Icon(Icons.note_alt))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(observation.photoFileRef!),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const CircleAvatar(
                                    child: Icon(Icons.broken_image_outlined),
                                  );
                                },
                              ),
                            ),
                      title: Text(observation.text ?? 'Untitled observation'),
                      subtitle:
                          Text(observation.timestamp.toLocal().toString()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showObservationDetails(observation),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FormFieldConfig {
  const _FormFieldConfig(this.fieldId, this.label, {this.maxLines = 1});

  final String fieldId;
  final String label;
  final int maxLines;
}

const _fieldConfigs = [
  _FormFieldConfig(InspectionFormFieldIds.buildingName, 'Building Name'),
  _FormFieldConfig(InspectionFormFieldIds.address, 'Address'),
  _FormFieldConfig(InspectionFormFieldIds.occupancyType, 'Occupancy Type'),
  _FormFieldConfig(
    InspectionFormFieldIds.constructionType,
    'Construction Type',
  ),
  _FormFieldConfig(
    InspectionFormFieldIds.alarmPanelLocation,
    'Alarm Panel Location',
  ),
  _FormFieldConfig(
    InspectionFormFieldIds.sprinklerRiserLocation,
    'Sprinkler Riser Location',
  ),
  _FormFieldConfig(
    InspectionFormFieldIds.fireProtectionSystems,
    'Fire Protection Systems',
    maxLines: 2,
  ),
  _FormFieldConfig(
    InspectionFormFieldIds.utilityShutoffs,
    'Utility Shutoffs',
    maxLines: 2,
  ),
  _FormFieldConfig(
    InspectionFormFieldIds.hazards,
    'Known Hazards',
    maxLines: 3,
  ),
  _FormFieldConfig(
    InspectionFormFieldIds.accessNotes,
    'Access Notes',
    maxLines: 3,
  ),
  _FormFieldConfig(
    InspectionFormFieldIds.notes,
    'Additional Notes',
    maxLines: 3,
  ),
];

class _VoiceMessage {
  _VoiceMessage(this.text, {required this.fromUser, this.isSystem = false});
  final String text;
  final bool fromUser;
  /// System confirmation messages (e.g. "Recorded: …") shown in a muted style.
  final bool isSystem;
}

class _VoiceSessionSheet extends ConsumerStatefulWidget {
  const _VoiceSessionSheet({
    required this.agent,
    required this.session,
    required this.onSessionUpdated,
    required this.onFloorplanRequested,
  });
  final VoiceAgent agent;
  final InspectionSession session;
  final Future<void> Function(InspectionSession) onSessionUpdated;
  final Future<void> Function() onFloorplanRequested;

  @override
  ConsumerState<_VoiceSessionSheet> createState() => _VoiceSessionSheetState();
}

class _VoiceSessionSheetState extends ConsumerState<_VoiceSessionSheet> {
  final List<_VoiceMessage> _messages = [];
  StreamSubscription<String>? _transcriptSub;
  StreamSubscription<String>? _responseSub;
  StreamSubscription<VoiceAction>? _actionSub;

  @override
  void initState() {
    super.initState();
    _transcriptSub = widget.agent.transcriptStream.listen((text) {
      if (!mounted) return;
      setState(() => _messages.add(_VoiceMessage(text, fromUser: true)));
    });
    _responseSub = widget.agent.responseStream.listen((text) {
      if (!mounted) return;
      setState(() => _messages.add(_VoiceMessage(text, fromUser: false)));
    });
    _actionSub = widget.agent.actionStream.listen(_handleAction);
    widget.agent.startListening(widget.session, ConversationHistory());
  }

  @override
  void dispose() {
    _transcriptSub?.cancel();
    _responseSub?.cancel();
    _actionSub?.cancel();
    widget.agent.stopListening();
    super.dispose();
  }

  Future<void> _handleAction(VoiceAction action) async {
    switch (action) {
      case RecordObservation(:final text):
        await _persistObservation(text: text);
      case TakePhoto(:final description):
        await _takePhotoObservation(description: description);
      case UploadFloorplan():
        await widget.onFloorplanRequested();
    }
  }

  Future<void> _persistObservation({required String text, String? photoPath}) async {
    final observation = Observation(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      text: text,
      photoFileRef: photoPath,
    );
    final updated = widget.session.copyWith(
      observations: [...widget.session.observations, observation],
    );
    await widget.onSessionUpdated(updated);
    if (!mounted) return;
    setState(() => _messages.add(
      _VoiceMessage('Recorded: "$text"', fromUser: false, isSystem: true),
    ));
  }

  Future<void> _takePhotoObservation({String? description}) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null || !mounted) return;
    final service = await ref.read(sessionServiceProvider.future);
    final permanentPath = await service.saveImage(photo.path);
    await _persistObservation(
      text: description ?? 'Photo observation',
      photoPath: permanentPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mock =
        widget.agent is MockVoiceAgent ? widget.agent as MockVoiceAgent : null;

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
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 320),
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
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
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
