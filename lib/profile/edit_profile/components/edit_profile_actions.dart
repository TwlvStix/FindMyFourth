import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Action buttons for the Edit Profile screen.
///
/// Displays Save and Delete Account buttons with proper loading states
/// and double-submit protection.
class EditProfileActions extends StatelessWidget {
  const EditProfileActions({
    super.key,
    required this.onSave,
    required this.onDelete,
    this.isSaving = false,
    this.isDeleting = false,
  });

  /// Callback when Save is pressed
  final VoidCallback onSave;

  /// Callback when Delete Account is pressed
  final VoidCallback onDelete;

  /// Whether a save operation is in progress
  final bool isSaving;

  /// Whether a delete operation is in progress
  final bool isDeleting;

  /// Whether any action is in progress (disables both buttons)
  bool get _isActionInProgress => isSaving || isDeleting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Save Button
          Semantics(
            button: true,
            label: 'Save profile changes',
            child: AppButtonEnhanced(
              text: 'Save Changes',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              fullWidth: true,
              leadingPhosphorIcon: AppPhosphorIcons.success,
              onPressed: _isActionInProgress ? null : onSave,
              isLoading: isSaving,
              enabled: !_isActionInProgress,
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // Delete Account Button
          Semantics(
            button: true,
            label: 'Delete your account',
            child: AppButtonEnhanced(
              text: 'Delete Account',
              variant: AppButtonVariant.destructiveOutlined,
              size: AppButtonSize.large,
              fullWidth: true,
              leadingPhosphorIcon: AppPhosphorIcons.trash,
              onPressed: _isActionInProgress ? null : onDelete,
              isLoading: isDeleting,
              enabled: !_isActionInProgress,
            ),
          ),
        ],
      ),
    );
  }
}
