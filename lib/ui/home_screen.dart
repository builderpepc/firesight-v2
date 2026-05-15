import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/di.dart';
import '../services/model/model_download_service.dart';

/// Home screen showing recent inspection sessions.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    final downloadStatus = ref.watch(modelDownloadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FireSight'),
        actions: [
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
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 24),
                  Text('Recent Sessions - TODO'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('session-new'),
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
    );
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
                  'Downloading Gemma 4 model… $receivedMb MB$totalMb$pct',
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
