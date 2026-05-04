import 'package:flutter/material.dart';

/// Active inspection screen with voice controls.
class InspectionScreen extends StatelessWidget {
  const InspectionScreen({super.key, this.sessionId});
  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sessionId != null ? 'New Inspection' : 'Session: $sessionId'),
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
