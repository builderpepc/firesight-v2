import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firesight/models/observation.dart';

class FloorplanViewer extends StatelessWidget {
  const FloorplanViewer({
    super.key,
    required this.floorplanPath,
    required this.observations,
    required this.onTap,
    this.onObservationTap,
  });

  final String floorplanPath;
  final List<Observation> observations;
  final Function(double x, double y) onTap;
  final Function(Observation observation)? onObservationTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          maxScale: 5.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final x = details.localPosition.dx / constraints.maxWidth;
              final y = details.localPosition.dy / constraints.maxHeight;
              onTap(x, y);
            },
            child: Stack(
              children: [
                Image.file(
                  File(floorplanPath),
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                ),
                ...observations
                    .where((obs) => obs.floorplanX != null && obs.floorplanY != null)
                    .map((obs) => Positioned(
                          left: obs.floorplanX! * constraints.maxWidth - 12,
                          top: obs.floorplanY! * constraints.maxHeight - 24,
                          child: GestureDetector(
                            onTap: () => onObservationTap?.call(obs),
                            child: const Icon(Icons.location_on, color: Colors.red, size: 24),
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
