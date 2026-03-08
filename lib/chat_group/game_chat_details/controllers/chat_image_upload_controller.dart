import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/utils/app_log.dart';
import '/providers/chat_provider.dart';
import '../components/chat_image_source_sheet.dart';
import '../components/chat_pending_upload_bubble.dart';

/// Controller for image selection, upload, and pending state management.
///
/// Extracted from GameChatDetailsWidget to reduce widget size and isolate
/// Firebase Storage operations.
class ChatImageUploadController {
  ChatImageUploadController({
    required this.chatId,
    required this.chatProvider,
    required this.onStateChanged,
    required this.isMounted,
    required this.getCurrentUserId,
  });

  final String chatId;
  final ChatProvider chatProvider;
  final VoidCallback onStateChanged;
  final bool Function() isMounted;
  final String? Function() getCurrentUserId;

  final List<PendingUploadItem> pendingUploads = [];
  final ImagePicker _picker = ImagePicker();

  /// Shows the image source selection sheet (camera or gallery).
  void showImageSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.navyDark,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.lg)),
      ),
      builder: (sheetCtx) => ChatImageSourceSheet(
        onGallerySelected: () {
          Navigator.of(sheetCtx).pop();
          pickAndSendImage(ImageSource.gallery);
        },
        onCameraSelected: () {
          Navigator.of(sheetCtx).pop();
          pickAndSendImage(ImageSource.camera);
        },
      ),
    );
  }

  /// Picks an image from the specified source and uploads it to Firebase Storage.
  Future<void> pickAndSendImage(ImageSource source) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70,
    );
    if (xFile == null || !isMounted()) return;

    final bytes = await xFile.readAsBytes();

    // Decode dimensions for aspect-ratio skeleton
    double? imgWidth, imgHeight;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      imgWidth = frame.image.width.toDouble();
      imgHeight = frame.image.height.toDouble();
      frame.image.dispose();
    } catch (_) {}

    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();
    if (!isMounted()) return;

    pendingUploads.add(PendingUploadItem(id: uploadId, previewBytes: bytes));
    onStateChanged();

    try {
      final path = 'chat_images/$chatId/${uploadId}_$currentUserId.jpg';
      final ref = FirebaseStorage.instance.ref().child(path);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(bytes, metadata);

      uploadTask.snapshotEvents.listen(
        (snapshot) {
          if (!isMounted()) return;
          final total = snapshot.totalBytes;
          final progress = total > 0 ? snapshot.bytesTransferred / total : 0.0;
          final idx = pendingUploads.indexWhere((u) => u.id == uploadId);
          if (idx != -1) {
            pendingUploads[idx] =
                pendingUploads[idx].copyWith(progress: progress);
            onStateChanged();
          }
        },
        onError: (_) {}, // errors are handled via await uploadTask below
        cancelOnError: true,
      );

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      if (!isMounted()) return;
      await chatProvider.sendImageMessage(
        chatId: chatId,
        senderId: currentUserId,
        imageUrl: downloadUrl,
        thumbnailUrl: downloadUrl,
        imageWidth: imgWidth,
        imageHeight: imgHeight,
      );

      if (!isMounted()) return;
      pendingUploads.removeWhere((u) => u.id == uploadId);
      onStateChanged();
    } catch (error, stackTrace) {
      AppLog.d('📷 Image upload error: $error\n$stackTrace');
      if (!isMounted()) return;
      pendingUploads.removeWhere((u) => u.id == uploadId);
      onStateChanged();
      rethrow; // Let caller handle error display
    }
  }

  /// Shows a snackbar for upload failure with retry option.
  void showUploadError(
    BuildContext context,
    Object error,
    ImageSource source,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          kDebugMode
              ? 'Upload error: $error'
              : 'Failed to send image. Please try again.',
        ),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => pickAndSendImage(source),
        ),
      ),
    );
  }
}
