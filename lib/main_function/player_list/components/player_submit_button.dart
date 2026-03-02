import 'package:flutter/material.dart';

import '/core/widgets/app_button_enhanced.dart';

class PlayerSubmitButton extends StatelessWidget {
  const PlayerSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButtonEnhanced(
        onPressed: isSubmitting
            ? null
            : () async {
                await onPressed();
              },
        text: isSubmitting ? 'Saving...' : 'Continue',
        variant: AppButtonVariant.primary,
        size: AppButtonSize.medium,
      ),
    );
  }
}
