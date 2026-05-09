import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firesight/core/di.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
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
  late final TextEditingController _nameController;
  late final TextEditingController _inspectorController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _inspectorController = TextEditingController();
    _loadSession();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _inspectorController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final service = await ref.read(sessionServiceProvider.future);
    if (widget.sessionId != null) {
      final session = await service.loadSession(widget.sessionId!);
      setState(() {
        _session = session;
        _isLoading = false;
      });
      _syncControllersFromSession();
    } else {
      final session = await service
          .createSession('New Inspection ${DateTime.now().toLocal()}');
      setState(() {
        _session = session;
        _isLoading = false;
      });
      _syncControllersFromSession();
    }
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

  Future<void> _openFocusedFloorplan() async {
    if (_session?.floorplanPath == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Floorplan Focus'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Pinch to zoom, drag to pan, and tap the floorplan to add a photo note.',
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
                        onTap: (x, y) async {
                          await _addObservationAt(x, y);
                          if (mounted) {
                            setState(() {});
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
                                    color: Colors.black.withOpacity(0.6),
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
            const SizedBox(height: 12),
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
