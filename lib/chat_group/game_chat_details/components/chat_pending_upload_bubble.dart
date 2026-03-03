import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';

class PendingUploadItem {
  const PendingUploadItem({
    required this.id,
    required this.previewBytes,
    this.progress = 0.0,
  });

  final String id;
  final Uint8List previewBytes;
  final double progress;

  PendingUploadItem copyWith({
    double? progress,
  }) {
    return PendingUploadItem(
      id: id,
      previewBytes: previewBytes,
      progress: progress ?? this.progress,
    );
  }
}

class ChatPendingUploadBubble extends StatelessWidget {
  const ChatPendingUploadBubble({
    super.key,
    required this.upload,
  });

  final PendingUploadItem upload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: AppSpacing.md,
        left: 60,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.memory(
                  upload.previewBytes,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: 200,
                  height: 200,
                  color: AppColors.overlayDark,
                ),
                CircularProgressIndicator(
                  value: upload.progress > 0 ? upload.progress : null,
                  color: AppColors.pure,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
