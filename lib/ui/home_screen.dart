import 'package:firesight/core/di.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/services/model/model_download_service.dart';
import 'package:firesight/services/session/session_service.dart';
import 'package:firesight/services/voice/voice_agent.dart';
import 'package:firesight/ui/widgets/voice_session_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

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
  void initState() {
    super.initState();
    // Trigger model download check after the first frame so the provider is
    // fully mounted before we call into it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(modelDownloadProvider.notifier).ensureDownloaded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final downloadStatus = ref.watch(modelDownloadProvider);

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
          IconButton(
            tooltip: 'Voice Agent Debug',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => context.pushNamed('debug-voice'),
          ),
        ],
      ),
      body: Column(
        children: [
          _ModelDownloadBanner(status: downloadStatus),
          Expanded(
            child: sessionsAsync.when(
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
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _openVoiceSession,
            icon: const Icon(Icons.mic),
            label: const Text('Voice Agent'),
            heroTag: 'voice_agent_fab',
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () async {
              await context.pushNamed('session-new');
              ref.invalidate(sessionsProvider);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Inspection'),
            heroTag: 'new_inspection_fab',
          ),
        ],
      ),
    );
  }

  Future<void> _openVoiceSession() async {
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

    // Use a placeholder session for the home screen
    final now = DateTime.now();
    final placeholderSession = InspectionSession(
      id: 'home-voice-placeholder',
      name: 'Home Screen Session',
      createdAt: now,
      updatedAt: now,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => VoiceSessionSheet(
        agent: agent,
        session: placeholderSession,
        onSessionUpdated: (updated) async {
          // No-op for placeholder
        },
        onFloorplanRequested: () async {
          // Notify that floorplan requires an active session
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Floorplan upload requires an active inspection. Try saying "start new inspection".',
                ),
              ),
            );
          }
        },
        onStartNewInspection: () {
          Navigator.pop(context);
          context.pushNamed('session-new').then((_) {
            if (mounted) ref.invalidate(sessionsProvider);
          });
        },
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

// ---------------------------------------------------------------------------
// Download banner
// ---------------------------------------------------------------------------

class _ModelDownloadBanner extends ConsumerWidget {
  const _ModelDownloadBanner({required this.status});

  final ModelDownloadStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (status) {
      ModelDownloadIdle() || ModelDownloadReady() => const SizedBox.shrink(),
      ModelDownloadChecking() => const LinearProgressIndicator(),
      ModelDownloadNeedsWifi() => _InfoBanner(
          icon: Icons.wifi,
          message: 'Gemma 4 model download requires WiFi (4.4 GB).',
          actionLabel: 'Download anyway',
          onAction: () =>
              ref.read(modelDownloadProvider.notifier).startDownloadOnMobile(),
        ),
      ModelDownloadInProgress(
        progress: final p,
        bytesReceived: final received,
        totalBytes: final total,
      ) =>
        _ProgressBanner(progress: p, bytesReceived: received, totalBytes: total),
      ModelDownloadExtracting() => const LinearProgressIndicator(),
      ModelDownloadFailed(message: final msg) => _InfoBanner(
          icon: Icons.error_outline,
          color: Colors.red.shade700,
          message: msg,
          actionLabel: 'Retry',
          onAction: () =>
              ref.read(modelDownloadProvider.notifier).retryDownload(),
        ),
    };
  }
}

class _ProgressBanner extends ConsumerWidget {
  const _ProgressBanner({
    required this.progress,
    required this.bytesReceived,
    required this.totalBytes,
  });

  final double? progress;
  final int bytesReceived;
  final int totalBytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivedMb = (bytesReceived / 1024 / 1024).toStringAsFixed(0);
    final totalMb = totalBytes > 0
        ? ' / ${(totalBytes / 1024 / 1024).toStringAsFixed(0)} MB'
        : '';
    final pct = progress != null ? ' (${(progress! * 100).toStringAsFixed(0)}%)' : '';

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.download, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Downloading Gemma 4 model... $receivedMb MB$totalMb$pct',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(modelDownloadProvider.notifier).cancelDownload(),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.color,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.secondary;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: effectiveColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: effectiveColor),
            ),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
