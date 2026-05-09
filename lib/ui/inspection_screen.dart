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

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final service = await ref.read(sessionServiceProvider.future);
    if (widget.sessionId != null) {
      final session = await service.loadSession(widget.sessionId!);
      setState(() {
        _session = session;
        _isLoading = false;
      });
    } else {
      final session = await service.createSession('New Inspection ${DateTime.now().toLocal()}');
      setState(() {
        _session = session;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFloorplan() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && _session != null) {
      final service = await ref.read(sessionServiceProvider.future);
      final permanentPath = await service.saveImage(image.path);
      final updatedSession = _session!.copyWith(floorplanPath: permanentPath);
      await service.saveSession(updatedSession);
      setState(() {
        _session = updatedSession;
      });
    }
  }

  Future<void> _saveSession() async {
    if (_session == null) return;

    try {
      final service = await ref.read(sessionServiceProvider.future);
      await service.saveSession(_session!);
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
          decoration: const InputDecoration(hintText: 'Enter observation details...'),
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

      await service.saveSession(updatedSession);
      setState(() {
        _session = updatedSession;
      });
    }
  }

  void _showObservationDetails(Observation observation) {
    showDialog(
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
              const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
      body: _session!.floorplanPath == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.layers_clear, size: 64, color: Colors.grey),
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
            )
          : FloorplanViewer(
              floorplanPath: _session!.floorplanPath!,
              observations: _session!.observations,
              onTap: _addObservationAt,
              onObservationTap: _showObservationDetails,
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
}
