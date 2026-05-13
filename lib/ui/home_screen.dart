import 'package:firesight/core/di.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/services/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home screen showing recent inspection sessions.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const Map<SessionSortOption, String> _sortLabels = {
    SessionSortOption.updatedAtDesc: 'Last Updated',
    SessionSortOption.createdAtDesc: 'Created Time',
    SessionSortOption.nameAsc: 'Name',
    SessionSortOption.inspectorAsc: 'Inspector',
  };

  SessionSortOption _sort = SessionSortOption.updatedAtDesc;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FireSight'),
        actions: [
          PopupMenuButton<SessionSortOption>(
            initialValue: _sort,
            tooltip: 'Sort Sessions',
            onSelected: (value) {
              setState(() {
                _sort = value;
              });
            },
            itemBuilder: (context) => _sortLabels.entries
                .map(
                  (entry) => PopupMenuItem<SessionSortOption>(
                    value: entry.key,
                    child: Text('Sort: ${entry.value}'),
                  ),
                )
                .toList(),
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => _exportSessions(context, ref),
            tooltip: 'Export Sessions',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(sessionsProvider),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            onPressed: () => _deleteAllSessions(context, ref),
            tooltip: 'Delete All Sessions',
          ),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          final sortedSessions = _sortSessions(sessions);
          if (sortedSessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 24),
                  Text('No recent sessions'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: sortedSessions.length,
            itemBuilder: (context, index) {
              final session = sortedSessions[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.description),
                ),
                title: Text(session.name),
                subtitle: Text(_buildSessionSubtitle(session)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteSession(context, ref, session),
                  tooltip: 'Delete Session',
                ),
                onTap: () async {
                  await context.pushNamed(
                    'session',
                    pathParameters: {'id': session.id},
                  );
                  ref.invalidate(sessionsProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.pushNamed('session-new');
          ref.invalidate(sessionsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
    );
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    SessionMetadata session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inspection'),
        content: Text('Are you sure you want to delete "${session.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = await ref.read(sessionServiceProvider.future);
        await service.deleteSession(session.id);
        ref.invalidate(sessionsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete session: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteAllSessions(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Inspections'),
        content: const Text(
          'Are you sure you want to delete ALL inspection sessions? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = await ref.read(sessionServiceProvider.future);
        await service.deleteAllSessions();
        ref.invalidate(sessionsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All sessions deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete sessions: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportSessions(BuildContext context, WidgetRef ref) async {
    final sessions = ref.read(sessionsProvider).value;
    if (sessions == null || sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sessions to export')),
      );
      return;
    }

    try {
      final exportService = await ref.read(sessionExportProvider.future);
      final file = await exportService.exportSessions(sessions);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  List<SessionMetadata> _sortSessions(List<SessionMetadata> sessions) {
    final sortedSessions = [...sessions];
    sortedSessions.sort((a, b) {
      switch (_sort) {
        case SessionSortOption.updatedAtDesc:
          return b.updatedAt.compareTo(a.updatedAt);
        case SessionSortOption.createdAtDesc:
          return b.createdAt.compareTo(a.createdAt);
        case SessionSortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SessionSortOption.inspectorAsc:
          final inspectorCompare = (a.inspectorId ?? '')
              .toLowerCase()
              .compareTo((b.inspectorId ?? '').toLowerCase());
          if (inspectorCompare != 0) {
            return inspectorCompare;
          }
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });
    return sortedSessions;
  }

  String _buildSessionSubtitle(SessionMetadata session) {
    final lines = <String>[];
    if ((session.inspectorId ?? '').trim().isNotEmpty) {
      lines.add('Inspector: ${session.inspectorId!.trim()}');
    }
    lines.add('Last updated: ${session.updatedAt.toLocal()}');
    return lines.join('\n');
  }
}
