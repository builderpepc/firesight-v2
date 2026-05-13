import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firesight/models/observation.dart';

/// Renders a floorplan image with observation pins positioned in normalized
/// (0–1) image coordinates. Pins and tap-to-annotate respect the actual
/// rendered image rect under [BoxFit.contain] (not the surrounding container),
/// so portrait/landscape mismatches don't offset pins.
///
/// When [pinPlacementMode] is true, pan/zoom is disabled and taps add pins;
/// when false, taps don't add pins and pan/zoom is enabled. This avoids the
/// gesture-arena conflict between [InteractiveViewer] and the inner tap
/// detector.
class FloorplanViewer extends StatefulWidget {
  const FloorplanViewer({
    super.key,
    required this.floorplanPath,
    required this.observations,
    this.onTap,
    this.onObservationTap,
    this.minScale = 1.0,
    this.maxScale = 5.0,
    this.pinPlacementMode = false,
  });

  final String floorplanPath;
  final List<Observation> observations;
  final void Function(double x, double y)? onTap;
  final void Function(Observation observation)? onObservationTap;
  final double minScale;
  final double maxScale;
  final bool pinPlacementMode;

  @override
  State<FloorplanViewer> createState() => _FloorplanViewerState();
}

class _FloorplanViewerState extends State<FloorplanViewer> {
  Size? _imageSize;
  Object? _imageError;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant FloorplanViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.floorplanPath != widget.floorplanPath) {
      setState(() {
        _imageSize = null;
        _imageError = null;
      });
      _resolveImageSize();
    }
  }

  void _resolveImageSize() {
    final completer = Completer<Size>();
    final stream =
        Image.file(File(widget.floorplanPath)).image.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) {
          completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        }
        stream.removeListener(listener);
      },
      onError: (error, _) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    completer.future.then((size) {
      if (mounted) setState(() => _imageSize = size);
    }).catchError((error) {
      if (mounted) setState(() => _imageError = error);
    });
  }

  /// The portion of [container] that the image actually covers under
  /// [BoxFit.contain]. Returns the full container if image dimensions aren't
  /// loaded yet (best-effort while image is still resolving).
  Rect _renderedImageRect(Size container) {
    final size = _imageSize;
    if (size == null || size.width <= 0 || size.height <= 0) {
      return Offset.zero & container;
    }
    final imageAspect = size.width / size.height;
    final containerAspect = container.width / container.height;
    double w, h;
    if (imageAspect > containerAspect) {
      w = container.width;
      h = container.width / imageAspect;
    } else {
      h = container.height;
      w = container.height * imageAspect;
    }
    final dx = (container.width - w) / 2;
    final dy = (container.height - h) / 2;
    return Rect.fromLTWH(dx, dy, w, h);
  }

  @override
  Widget build(BuildContext context) {
    if (_imageError != null) {
      return _buildErrorPlaceholder(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        final imageRect = _renderedImageRect(containerSize);

        final tapHandler = (widget.pinPlacementMode && widget.onTap != null)
            ? (TapUpDetails details) {
                final p = details.localPosition;
                if (!imageRect.contains(p)) return;
                final x = (p.dx - imageRect.left) / imageRect.width;
                final y = (p.dy - imageRect.top) / imageRect.height;
                widget.onTap!(x, y);
              }
            : null;

        return InteractiveViewer(
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          panEnabled: !widget.pinPlacementMode,
          scaleEnabled: !widget.pinPlacementMode,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: tapHandler,
            child: Stack(
              children: [
                Image.file(
                  File(widget.floorplanPath),
                  fit: BoxFit.contain,
                  width: containerSize.width,
                  height: containerSize.height,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildErrorPlaceholder(context),
                ),
                ...widget.observations
                    .where((obs) =>
                        obs.floorplanX != null && obs.floorplanY != null)
                    .map((obs) => Positioned(
                          left: imageRect.left +
                              obs.floorplanX! * imageRect.width -
                              12,
                          top: imageRect.top +
                              obs.floorplanY! * imageRect.height -
                              24,
                          child: GestureDetector(
                            onTap: () => widget.onObservationTap?.call(obs),
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 24),
                          ),
                        )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Saved floorplan image is unavailable'),
        ],
      ),
    );
  }
}
