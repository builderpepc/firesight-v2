import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home screen showing recent inspection sessions.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FireSight'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text('Recent Sessions - TODO'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('session-new'),
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
    );
  }
}
