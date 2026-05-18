import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firesight/core/constants.dart';

class ObservationEditorDialog extends StatefulWidget {
  const ObservationEditorDialog({
    super.key,
    this.initialText,
    this.initialCategory,
    this.initialPhotoPath,
    required this.onSave,
  });

  final String? initialText;
  final String? initialCategory;
  final String? initialPhotoPath;
  final Function(String text, String category, String? photoPath) onSave;

  @override
  State<ObservationEditorDialog> createState() => _ObservationEditorDialogState();
}

class _ObservationEditorDialogState extends State<ObservationEditorDialog> {
  late TextEditingController _textController;
  late String _selectedCategory;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _selectedCategory = widget.initialCategory ?? kObservationCategories.first;
    _photoPath = widget.initialPhotoPath;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _retakePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _photoPath = photo.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialText == null ? 'Add Observation' : 'Edit Observation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_photoPath != null) ...[
              Semantics(
                label: 'Observation photo preview',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_photoPath!),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _retakePhoto,
                icon: const Icon(Icons.refresh),
                label: const Text('Retake Photo'),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: kObservationCategories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Enter observation details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              autofocus: widget.initialPhotoPath == null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => widget.onSave(
            _textController.text.trim(),
            _selectedCategory,
            _photoPath,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
