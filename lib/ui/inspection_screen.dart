import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active inspection screen with voice controls.
class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({super.key, this.sessionId});
  final String? sessionId;

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  @override
  void initState() {
    super.initState();
    // TODO: initialise voice agent and start/resume session
  }

  @override
  void dispose() {
    // TODO: stop recording and dispose voice agent
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionId == null ? 'New Inspection' : 'Session: ${widget.sessionId}'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text('Voice Interface - TODO'),
          ],
        ),
      ),
    );
  }
}
