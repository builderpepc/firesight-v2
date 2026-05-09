import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firesight/models/observation.dart';

class FloorplanViewer extends StatelessWidget {
  const FloorplanViewer({
    super.key,
    required this.floorplanPath,
    required this.observations,
    this.onTap,
    this.onObservationTap,
    this.minScale = 1.0,
    this.maxScale = 5.0,
  });

  final String floorplanPath;
  final List<Observation> observations;
  final Function(double x, double y)? onTap;
  final Function(Observation observation)? onObservationTap;
  final double minScale;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          minScale: minScale,
          maxScale: maxScale,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onTap == null
                ? null
                : (details) {
                    final x = details.localPosition.dx / constraints.maxWidth;
                    final y = details.localPosition.dy / constraints.maxHeight;
                    onTap!(x, y);
                  },
            child: Stack(
              children: [
                Image.file(
                  File(floorplanPath),
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Saved floorplan image is unavailable'),
                        ],
                      ),
                    );
                  },
                ),
                ...observations
                    .where((obs) =>
                        obs.floorplanX != null && obs.floorplanY != null)
                    .map((obs) => Positioned(
                          left: obs.floorplanX! * constraints.maxWidth - 12,
                          top: obs.floorplanY! * constraints.maxHeight - 24,
                          child: GestureDetector(
                            onTap: () => onObservationTap?.call(obs),
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
}
