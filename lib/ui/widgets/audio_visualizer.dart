import 'package:flutter/material.dart';

class AudioVisualizer extends StatelessWidget {
  const AudioVisualizer({
    super.key,
    required this.audioLevelStream,
    this.isProcessing = false,
  });

  final Stream<double> audioLevelStream;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: audioLevelStream,
      initialData: 0.0,
      builder: (context, snapshot) {
        final level = snapshot.data ?? 0.0;
        
        return SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (index) {
              // Create a symmetrical wave effect
              final distanceFromCenter = (index - 7).abs();
              final multiplier = 1.0 - (distanceFromCenter / 10.0);
              
              // If processing (thinking), show a pulsing animation instead of live audio
              final height = isProcessing 
                ? 10.0 + (multiplier * 20.0) 
                : 4.0 + (level * 36.0 * multiplier);
                
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: isProcessing 
                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
