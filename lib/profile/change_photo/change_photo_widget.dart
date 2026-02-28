import 'dart:io';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/utils/app_util.dart';
import '/utils/profile_image_picker.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/utils/upload_data.dart';
import '/core/design_tokens/border_radius.dart';
import 'package:flutter/material.dart';

class ChangePhotoWidget extends StatefulWidget {
  const ChangePhotoWidget({super.key});

  @override
  State<ChangePhotoWidget> createState() => _ChangePhotoWidgetState();
}

class _ChangePhotoWidgetState extends State<ChangePhotoWidget> {
  bool isDataUploadingUploadDataJ3j = false;
  UploadedFile uploadedLocalFileUploadDataJ3j =
      UploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrlUploadDataJ3j = '';

  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FairwayBackgroundLight(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxxl),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: 350.0,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(0.0),
              bottomRight: Radius.circular(0.0),
              topLeft: Radius.circular(AppBorderRadius.lg),
              topRight: Radius.circular(AppBorderRadius.lg),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxs),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            thickness: 3.0,
                            indent: 150.0,
                            endIndent: 150.0,
                            color: AppColors.navyDark,
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(0.0, AppSpacing.xxs, AppSpacing.md, 0.0),
                                child: Text(
                                  'Change Profile Picture',
                                  style: AppTypography.headlineMediumSans.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: AppSpacing.xs),
                                child: Text(
                                  'Upload a new photo below in order to change your profile picture.',
                                  style: AppTypography.labelMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.md),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100.0,
                                height: 100.0,
                                decoration: BoxDecoration(
                                  color: AppColors.mist,
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(AppSpacing.xxs),
                                      child: AuthUserStreamWidget(
                                        builder: (context) => Container(
                                          width: 120.0,
                                          height: 120.0,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                          ),
                                          child: Image.network(
                                            valueOrDefault<String>(
                                              currentUserPhoto,
                                              'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                            ),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              color: AppColors.navyLight,
                                              child: Icon(
                                                Icons.person,
                                                size: 60,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: AppSpacing.allXxs,
                                      child: Container(
                                        width: 120.0,
                                        height: 120.0,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.network(
                                          valueOrDefault<String>(
                                            uploadedFileUrlUploadDataJ3j,
                                            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                          ),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: AppColors.navyLight,
                                            child: Icon(
                                              Icons.person,
                                              size: 60,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(0.0, AppSpacing.xl, 0.0, AppSpacing.xxxl + AppSpacing.sm),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              AppButtonEnhanced(
                                onPressed: () async {
                                  final croppedPath =
                                      await showProfileImageSourceSheet(
                                          context);
                                  if (croppedPath == null) return;

                                  if (mounted) {
                                    setState(() =>
                                        isDataUploadingUploadDataJ3j = true);
                                  }
                                  try {
                                    final bytes = await File(croppedPath)
                                        .readAsBytes();
                                    final storagePath =
                                        'users/$currentUserUid/profile_photos/${DateTime.now().millisecondsSinceEpoch}.jpg';
                                    final downloadUrl =
                                        await uploadData(storagePath, bytes);
                                    if (downloadUrl != null && mounted) {
                                      setState(() {
                                        uploadedFileUrlUploadDataJ3j =
                                            downloadUrl;
                                      });
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() =>
                                          isDataUploadingUploadDataJ3j =
                                              false);
                                    }
                                  }
                                },
                                text: 'Upload Image',
                                variant: AppButtonVariant.secondary,
                                size: AppButtonSize.medium,
                              ),
                              AppButtonEnhanced(
                                onPressed: () async {
                                  if (isDataUploadingUploadDataJ3j) {
                                    showUploadMessage(
                                      context,
                                      'Upload in progress. Please wait.',
                                    );
                                    return;
                                  }
                                  if (uploadedFileUrlUploadDataJ3j.isEmpty) {
                                    showUploadMessage(
                                      context,
                                      'Please upload a photo before saving.',
                                    );
                                    return;
                                  }
                                  await currentUserReference!
                                      .update(createUsersRecordData(
                                    photoUrl:
                                        uploadedFileUrlUploadDataJ3j,
                                  ));
                                  Navigator.pop(context);
                                },
                                text: 'Save Changes',
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.medium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
