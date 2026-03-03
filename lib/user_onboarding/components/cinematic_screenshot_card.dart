import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';

class CinematicScreenshotCard extends StatelessWidget {
  final String imagePath;

  const CinematicScreenshotCard({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * 0.8,
            maxHeight: constraints.maxHeight,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
