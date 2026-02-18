import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Shows a bottom sheet asking the user to pick Camera or Gallery,
/// then opens the crop screen. Returns the cropped file path, or null
/// if the user cancels at any step.
Future<String?> showProfileImageSourceSheet(BuildContext context) async {
  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Camera'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Photo Library'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  return pickAndCropProfilePhoto(source: source);
}

/// Picks an image from [source] and opens the UCrop / iOS crop UI
/// with a locked 1:1 square, max 512×512, 85% JPEG quality.
/// Returns the cropped file path, or null on cancel/error.
Future<String?> pickAndCropProfilePhoto({required ImageSource source}) async {
  final XFile? picked = await ImagePicker().pickImage(source: source);
  if (picked == null) return null;

  final CroppedFile? cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 85,
    maxWidth: 512,
    maxHeight: 512,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Profile Photo',
        lockAspectRatio: true,
        initAspectRatio: CropAspectRatioPreset.square,
        showCropGrid: true,
        hideBottomControls: false,
      ),
      IOSUiSettings(
        title: 'Crop Profile Photo',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
        rotateButtonsHidden: false,
        minimumAspectRatio: 1.0,
      ),
    ],
  );
  return cropped?.path;
}
